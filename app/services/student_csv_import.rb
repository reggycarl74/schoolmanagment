require "csv"

class StudentCsvImport
  class Error < StandardError; end

  REQUIRED_HEADERS = %w[admission_number first_name last_name date_of_birth gender admitted_on].freeze
  HEADERS = (REQUIRED_HEADERS + %w[status medical_notes enrolled_on]).freeze
  MAX_BYTES = 2.megabytes

  def self.template
    CSV.generate { |csv| csv << HEADERS }
  end

  def initialize(school:, classroom:, file:)
    @school, @classroom, @file = school, classroom, file
  end

  def call
    raise Error, "Select a CSV file." unless @file.respond_to?(:read)
    raise Error, "Select a class belonging to your school." unless @classroom&.school_id == @school.id
    text = @file.read(MAX_BYTES + 1).to_s
    raise Error, "The CSV must be smaller than 2 MB." if text.bytesize > MAX_BYTES
    text = text.dup.force_encoding(Encoding::UTF_8).delete_prefix("\uFEFF")
    raise Error, "Save the CSV with UTF-8 encoding." unless text.valid_encoding?
    table = CSV.parse(text, headers: true, skip_blanks: true)
    headers = table.headers.map { |header| header&.strip&.downcase }
    missing = REQUIRED_HEADERS - headers
    raise Error, "Missing columns: #{missing.join(', ')}." if missing.any?
    raise Error, "Column names must be unique and cannot be blank." if headers.any?(&:blank?) || headers.uniq != headers
    unknown = headers - HEADERS
    raise Error, "Unknown columns: #{unknown.join(', ')}. Use the downloadable template." if unknown.any?
    count = 0
    seen = {}
    Student.transaction(requires_new: true) do
      table.each_with_index do |row, index|
        next if row.fields.all?(&:blank?)
        begin
          raise Error, "Too many values in this row." if row.fields.length > headers.length
          values = headers.zip(row.fields).to_h.transform_values { |value| value&.strip }
          REQUIRED_HEADERS.each { |key| raise Error, "#{key} is required." if values[key].blank? }
          number = values.fetch("admission_number")
          raise Error, "Duplicate admission_number #{number}." if seen[number.downcase]
          seen[number.downcase] = true
          %w[date_of_birth admitted_on enrolled_on].each do |key|
            next if values[key].blank?
            raise Error, "#{key} must be a valid date in YYYY-MM-DD format." unless values[key].match?(/\A\d{4}-\d{2}-\d{2}\z/)
            begin
              values[key] = Date.iso8601(values[key])
            rescue Date::Error
              raise Error, "#{key} must be a valid date in YYYY-MM-DD format."
            end
          end
          { "gender" => Student.genders, "status" => Student.statuses }.each do |key, choices|
            next if values[key].blank?
            values[key] = values[key].downcase
            raise Error, "#{key} must be one of: #{choices.keys.join(', ')}." unless choices.key?(values[key])
          end
          student = @school.students.find_or_initialize_by(admission_number: number)
          conflict = student.enrollments.joins(:classroom).where(classrooms: { academic_year_id: @classroom.academic_year_id }).where.not(classroom_id: @classroom.id).where(status: :enrolled).exists?
          raise Error, "#{number} is already enrolled in another class for this academic year. Transfer the student separately." if conflict
          attributes = values.slice(*REQUIRED_HEADERS)
          attributes["status"] = values["status"] if values["status"].present?
          attributes["medical_notes"] = values["medical_notes"] if values["medical_notes"].present?
          student.assign_attributes(attributes)
          student.save!
          enrollment = student.enrollments.find_or_initialize_by(classroom: @classroom)
          if enrollment.new_record?
            enrollment.enrolled_on = values["enrolled_on"].presence || student.admitted_on
            enrollment.save!
          end
          count += 1
        rescue Error, ActiveRecord::RecordInvalid => error
          raise Error, "Row #{index + 2}: #{error.message}"
        end
      end
      raise Error, "The CSV contains no students." if count.zero?
    end
    count
  rescue CSV::MalformedCSVError
    raise Error, "The file is not a valid CSV. Check its quoting and save it as CSV UTF-8."
  rescue ActiveRecord::RecordNotUnique
    raise Error, "An admission number or enrollment already exists. Check for duplicates and retry."
  end
end
