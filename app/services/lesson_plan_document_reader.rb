require "open3"
require "zip"
require "nokogiri"

class LessonPlanDocumentReader
  HEADINGS = {
    topic: /\A(?:topic|lesson topic)\s*[:\-]?\s*(.*)/i,
    objectives: /\A(?:objectives?|learning objectives?)\s*[:\-]?\s*(.*)/i,
    materials: /\A(?:materials?|resources?)\s*[:\-]?\s*(.*)/i,
    content: /\A(?:content|activities|lesson content|teaching activities)\s*[:\-]?\s*(.*)/i,
    homework: /\A(?:homework|follow[ -]?up|assignment)\s*[:\-]?\s*(.*)/i
  }.freeze

  def self.prefill(note, uploads) = new(note, uploads).prefill

  def initialize(note, uploads)
    @note = note
    @uploads = uploads
  end

  def prefill
    text = @uploads.filter_map { |upload| extract(upload) }.join("\n\n").strip
    return @note if text.blank?

    sections = sections_from(text)
    @note.topic = sections[:topic].presence || inferred_topic if @note.topic.blank?
    %i[objectives materials content homework].each do |field|
      @note.public_send("#{field}=", sections[field]) if @note.public_send(field).blank? && sections[field].present?
    end
    @note.content = text if @note.content.blank?
    @note
  end

  private

  def extract(upload)
    case upload.content_type
    when "text/plain" then File.read(upload.tempfile.path, encoding: "bom|utf-8")
    when "application/pdf" then extract_pdf(upload.tempfile.path)
    when "application/vnd.openxmlformats-officedocument.wordprocessingml.document" then extract_zip_xml(upload.tempfile.path, %r{\Aword/document\.xml\z})
    when "application/vnd.openxmlformats-officedocument.presentationml.presentation" then extract_zip_xml(upload.tempfile.path, %r{\Appt/slides/slide\d+\.xml\z})
    end
  rescue StandardError => error
    Rails.logger.warn("Could not extract lesson-plan upload #{upload.original_filename}: #{error.message}")
    nil
  end

  def extract_pdf(path)
    output, status = Open3.capture2("pdftotext", "-layout", path, "-")
    status.success? ? output : nil
  rescue Errno::ENOENT
    nil
  end

  def extract_zip_xml(path, pattern)
    Zip::File.open(path) do |archive|
      archive.entries.select { |entry| entry.name.match?(pattern) }.sort_by(&:name).map do |entry|
        Nokogiri::XML(entry.get_input_stream.read).xpath("//*[local-name()='t']").map(&:text).join("\n")
      end.join("\n")
    end
  end

  def sections_from(text)
    sections = Hash.new { |hash, key| hash[key] = [] }
    current = nil
    text.each_line do |line|
      stripped = line.strip
      heading = HEADINGS.find { |_field, pattern| stripped.match?(pattern) }
      if heading
        current = heading.first
        inline = stripped.match(heading.last)[1]
        sections[current] << inline if inline.present?
      elsif current && stripped.present?
        sections[current] << stripped
      end
    end
    sections.transform_values { |lines| lines.join("\n").strip }
  end

  def inferred_topic
    File.basename(@uploads.first.original_filename, ".*").tr("_-", " ").titleize
  end
end
