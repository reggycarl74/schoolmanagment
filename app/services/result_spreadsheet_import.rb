class ResultSpreadsheetImport
  class Error < StandardError; end

  def initialize(file:, classroom:, course:, term:, components:, graded_by:)
    @file, @classroom, @course, @term, @components, @graded_by = file, classroom, course, term, components, graded_by
  end

  def call
    raise Error, "Choose an Excel or CSV file." unless @file
    extension = File.extname(@file.original_filename).delete(".").downcase
    raise Error, "Use an .xlsx, .xls, or .csv file." unless extension.in?(%w[xlsx xls csv])

    sheet = Roo::Spreadsheet.open(@file.path, extension: extension.to_sym)
    headers = sheet.row(1).map { |value| value.to_s.parameterize(separator: "_") }
    admission_column = headers.index("admission_number")
    raise Error, "The spreadsheet needs an admission_number column." unless admission_column

    component_columns = @components.to_h { |key, definition| [ key, headers.index(definition[:title].parameterize(separator: "_")) ] }
    missing = component_columns.select { |_key, column| column.nil? }.keys
    raise Error, "Missing result columns: #{missing.map { |key| @components[key][:title] }.join(', ')}." if missing.any?

    assessments = build_assessments
    imported = 0
    ActiveRecord::Base.transaction do
      (2..sheet.last_row).each do |row_number|
        row = sheet.row(row_number)
        admission_number = normalize_admission_number(row[admission_column])
        next if admission_number.blank?

        enrollment = @classroom.enrollments.joins(:student).find_by!(students: { admission_number: })
        component_columns.each do |key, column|
          value = row[column]
          next if value.blank?

          grade = assessments.fetch(key).grades.find_or_initialize_by(enrollment:)
          grade.assign_attributes(points: value, graded_at: Time.current, graded_by: @graded_by)
          grade.save!
        end
        imported += 1
      rescue ActiveRecord::RecordNotFound
        raise Error, "Row #{row_number}: admission number #{admission_number.inspect} is not enrolled in #{@classroom.name}."
      rescue ActiveRecord::RecordInvalid => error
        raise Error, "Row #{row_number}: #{error.record.errors.full_messages.to_sentence}."
      end
    end
    imported
  rescue Roo::FileNotFound, Roo::UnknownExtension, Zip::Error => error
    raise Error, "The spreadsheet could not be read: #{error.message}"
  end

  private

  def normalize_admission_number(value)
    value.is_a?(Numeric) ? value.to_i.to_s : value.to_s.strip
  end

  def build_assessments
    @components.to_h do |key, definition|
      assessment = @course.assessments.find_or_initialize_by(title: definition[:title])
      assessment.update!(maximum_points: definition[:maximum_points], kind: definition[:kind], weight: 1, due_on: @term.ends_on)
      [ key, assessment ]
    end
  end
end
