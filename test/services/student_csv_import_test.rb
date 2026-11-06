require "test_helper"
require "stringio"

class StudentCsvImportTest < ActiveSupport::TestCase
  self.fixture_table_names = %w[schools academic_years grade_levels classrooms students enrollments users]

  test "creates and enrolls students and repeat uploads do not duplicate them" do
    assert_difference [ "Student.count", "Enrollment.count" ], 1 do
      assert_equal 1, import(csv)
    end
    assert_no_difference [ "Student.count", "Enrollment.count" ] do
      import(csv)
    end
    student = schools(:demo).students.find_by!(admission_number: "00123")
    assert_equal classrooms(:assigned), student.enrollments.first.classroom
    assert_equal Date.new(2026, 8, 1), student.enrollments.first.enrolled_on
  end

  test "invalid later row rolls back students and enrollments" do
    content = csv + "00234,Bad,Date,2015-02-30,male,2026-08-01\n"
    assert_no_difference [ "Student.count", "Enrollment.count" ] do
      error = assert_raises(StudentCsvImport::Error) { import(content) }
      assert_match "Row 3", error.message
    end
  end

  test "existing student details update without changing enrollment" do
    content = csv.sub("00123", "V001").sub("Jane", "Updated")
    assert_no_difference [ "Student.count", "Enrollment.count" ] do
      import(content)
    end
    assert_equal "Updated", students(:visible).reload.first_name
  end

  test "another class in same year is rejected" do
    error = assert_raises(StudentCsvImport::Error) { import(csv.sub("00123", "H001")) }
    assert_match "already enrolled", error.message
    assert_equal "Hidden", students(:hidden).reload.first_name
  end

  test "rejects missing headers duplicate admissions and invalid enums" do
    [ "first_name\nJane\n", csv + csv.lines.last, csv.sub("female", "invalid") ].each do |content|
      assert_no_difference [ "Student.count", "Enrollment.count" ] do
        assert_raises(StudentCsvImport::Error) { import(content) }
      end
    end
  end

  test "accepts UTF-8 BOM and optional enrollment date" do
    content = "\uFEFF" + csv.lines.first.strip + ",enrolled_on\n" + csv.lines.last.strip + ",2026-09-01\n"
    import(content)
    assert_equal Date.new(2026, 9, 1), Student.find_by!(admission_number: "00123").enrollments.first.enrolled_on
  end

  test "rejects empty missing oversized and malformed files" do
    [ "", StudentCsvImport.template, '"unterminated', "x" * (StudentCsvImport::MAX_BYTES + 1) ].each do |content|
      assert_raises(StudentCsvImport::Error) { import(content) }
    end
    assert_raises(StudentCsvImport::Error) do
      StudentCsvImport.new(school: schools(:demo), classroom: classrooms(:assigned), file: nil).call
    end
  end

  test "rejects classes from another school" do
    classroom = classrooms(:assigned)
    classroom.school_id = -1
    assert_raises(StudentCsvImport::Error) do
      StudentCsvImport.new(school: schools(:demo), classroom:, file: StringIO.new(csv)).call
    end
  end

  private

  def import(content)
    StudentCsvImport.new(school: schools(:demo), classroom: classrooms(:assigned), file: StringIO.new(content)).call
  end

  def csv
    "admission_number,first_name,last_name,date_of_birth,gender,admitted_on\n00123,Jane,Smith,2015-02-01,female,2026-08-01\n"
  end
end
