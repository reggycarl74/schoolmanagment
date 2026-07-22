puts "Seeding demo school data..."

school = School.find_or_initialize_by(code: "DEMO")
school.assign_attributes(
  name: "Demo Academy",
  time_zone: "Europe/Berlin",
  email: "office@example.test",
  phone: "+49 30 555 0100",
  address: "10 Learning Lane, Berlin"
)
school.save!

administrator = school.users.find_or_initialize_by(email: "admin@example.test")
administrator.assign_attributes(
  first_name: "Demo",
  last_name: "Administrator",
  role: :administrator,
  active: true,
  password: ENV.fetch("ADMIN_PASSWORD", "ChangeMe123!")
)
administrator.save!

academic_year = school.academic_years.find_or_initialize_by(name: "2026/2027")
academic_year.assign_attributes(starts_on: Date.new(2026, 8, 1), ends_on: Date.new(2027, 7, 31), current: true)
academic_year.save!

term_data = [
  [ "Term 1", 1, Date.new(2026, 8, 1), Date.new(2026, 12, 18) ],
  [ "Term 2", 2, Date.new(2027, 1, 4), Date.new(2027, 3, 26) ],
  [ "Term 3", 3, Date.new(2027, 4, 12), Date.new(2027, 7, 31) ]
]

terms = term_data.map do |name, position, starts_on, ends_on|
  term = academic_year.terms.find_or_initialize_by(position:)
  term.assign_attributes(name:, starts_on:, ends_on:)
  term.save!
  term
end
terms.first.update!(reopening_date: terms.second.starts_on)

grade_levels = [ "Grade 4", "Grade 5", "Grade 6" ].map.with_index(4) do |name, position|
  grade = school.grade_levels.find_or_initialize_by(name:)
  grade.assign_attributes(position:)
  grade.save!
  grade
end

teacher_data = [
  [ "T001", "Ama", "Mensah", "ama.mensah@example.test" ],
  [ "T002", "Daniel", "Owusu", "daniel.owusu@example.test" ],
  [ "T003", "Grace", "Boateng", "grace.boateng@example.test" ],
  [ "T004", "Michael", "Asare", "michael.asare@example.test" ],
  [ "T005", "Linda", "Ofori", "linda.ofori@example.test" ]
]

teachers = teacher_data.map.with_index do |(employee_number, first_name, last_name, email), index|
  user = school.users.find_or_initialize_by(email:)
  user.assign_attributes(
    first_name:,
    last_name:,
    role: :teacher,
    active: true,
    password: ENV.fetch("TEACHER_PASSWORD", "Teacher123!")
  )
  user.save!

  teacher = school.teachers.find_or_initialize_by(employee_number:)
  teacher.assign_attributes(
    first_name:,
    last_name:,
    email:,
    phone: "+49 30 555 #{format('%04d', 200 + index)}",
    hired_on: Date.new(2022, 8, 1) + index.months,
    active: true,
    user:
  )
  teacher.save!
  teacher
end

subject_data = [
  [ "Mathematics", "MATH" ],
  [ "English Language", "ENG" ],
  [ "Integrated Science", "SCI" ],
  [ "Social Studies", "SOC" ],
  [ "Information Technology", "ICT" ]
]

subjects = subject_data.map do |name, code|
  subject = school.subjects.find_or_initialize_by(code:)
  subject.assign_attributes(name:)
  subject.save!
  subject
end

classrooms = [ "Grade 4A", "Grade 5A", "Grade 6A" ].each_with_index.map do |name, index|
  classroom = school.classrooms.find_or_initialize_by(academic_year:, name:)
  classroom.assign_attributes(
    grade_level: grade_levels.fetch(index),
    homeroom_teacher: teachers.fetch(index),
    capacity: 30
  )
  classroom.save!
  classroom
end

student_names = [
  [ "Abena", "Konadu", :female ], [ "Farhan", "Adam", :male ],
  [ "Joseph", "Anderson", :male ], [ "Nana", "Antwi", :male ],
  [ "Akosua", "Asare", :female ], [ "Brian", "Avorgbedor", :male ],
  [ "Mohammed", "Mashood", :male ], [ "David", "Ofori", :male ],
  [ "Jael", "Agbeke", :female ], [ "Shaimawu", "Salawudeen", :female ],
  [ "Uriella", "Shika", :female ], [ "Emma", "Odum", :female ],
  [ "Kylie", "Tetevi", :female ], [ "Jordana", "Tetteh", :female ],
  [ "Alvin", "Adzido", :male ], [ "Kwame", "Appiah", :male ],
  [ "Esi", "Amoako", :female ], [ "Samuel", "Addo", :male ]
]

students = student_names.map.with_index do |(first_name, last_name, gender), index|
  classroom = classrooms.fetch(index / 6)
  admission_number = format("STD%04d", index + 1)
  student = school.students.find_or_initialize_by(admission_number:)
  student.assign_attributes(
    first_name:,
    last_name:,
    gender:,
    date_of_birth: Date.new(2015 - (index / 6), (index % 12) + 1, ((index * 3) % 25) + 1),
    admitted_on: academic_year.starts_on,
    status: :active
  )
  student.save!

  enrollment = Enrollment.find_or_initialize_by(student:, classroom:)
  enrollment.assign_attributes(enrolled_on: academic_year.starts_on, status: :enrolled)
  enrollment.save!
  student
end

assessment_components = [
  [ "Mid Term", 20, :exam ],
  [ "Class Work", 10, :assignment ],
  [ "Class Test", 10, :quiz ],
  [ "Project", 10, :project ],
  [ "Exam", 50, :exam ]
]

assessment_components.each_with_index do |(title, maximum_points, kind), position|
  component = school.assessment_components.find_or_initialize_by(title:)
  component.assign_attributes(maximum_points:, kind:, position: position + 1, active: true)
  component.save!
end

[ [ "A", 80, "Excellent" ], [ "B", 70, "Very good" ], [ "C", 60, "Good" ],
  [ "D", 50, "Pass" ], [ "F", 0, "Needs improvement" ] ].each do |letter, minimum_percentage, remark|
  scale = school.grading_scales.find_or_initialize_by(letter:)
  scale.update!(minimum_percentage:, remark:)
end

classrooms.each_with_index do |classroom, classroom_index|
  classroom_enrollments = classroom.enrollments.includes(:student).order(:id)

  subjects.each_with_index do |subject, subject_index|
    course = CourseSection.find_or_create_by!(classroom:, subject:, term: terms.first)
    teacher = teachers.fetch((classroom_index + subject_index) % teachers.length)
    TeachingAssignment.find_or_create_by!(course_section: course, teacher:)

    assessment_components.each_with_index do |(title, maximum_points, kind), component_index|
      assessment = course.assessments.find_or_initialize_by(title:)
      assessment.assign_attributes(
        maximum_points:,
        kind:,
        weight: 1,
        due_on: terms.first.ends_on,
        status: :published,
        published_at: terms.first.ends_on.end_of_day
      )
      assessment.save!

      classroom_enrollments.each_with_index do |enrollment, student_index|
        performance = 0.62 + (((student_index + subject_index + component_index) % 7) * 0.045)
        points = (maximum_points * performance).round(2)
        grade = assessment.grades.find_or_initialize_by(enrollment:)
        grade.assign_attributes(points:, graded_at: terms.first.ends_on.end_of_day)
        grade.save!
      end
    end
  end
end

classrooms.each do |classroom|
  classroom.enrollments.where(status: :enrolled).find_each.with_index do |enrollment, index|
    5.times do |day_offset|
      date = academic_year.starts_on + day_offset.days
      record = AttendanceRecord.find_or_initialize_by(enrollment:, attendance_date: date)
      record.assign_attributes(status: ((index + day_offset) % 11).zero? ? :absent : :present, recorded_by: administrator)
      record.save!
    end
  end
end

students.first(3).each_with_index do |student, index|
  guardian = school.guardians.find_or_initialize_by(phone: "+49 30 555 #{format('%04d', 500 + index)}")
  guardian.assign_attributes(first_name: "Parent", last_name: student.last_name, email: "parent#{index + 1}@example.test")
  guardian.save!
  StudentGuardian.find_or_create_by!(student:, guardian:) do |link|
    link.relationship = "Parent"
    link.primary_contact = true
  end
  parent_user = school.users.find_or_initialize_by(email: guardian.email)
  parent_user.assign_attributes(first_name: guardian.first_name, last_name: guardian.last_name, role: :parent, active: true, guardian:, password: ENV.fetch("PARENT_PASSWORD", "Parent123!"))
  parent_user.save!
end

student = students.first
student_user = school.users.find_or_initialize_by(email: "student@example.test")
student_user.assign_attributes(first_name: student.first_name, last_name: student.last_name, role: :student, active: true, student:, password: ENV.fetch("STUDENT_PASSWORD", "Student123!"))
student_user.save!

school.announcements.find_or_create_by!(title: "Welcome to the new academic year") do |announcement|
  announcement.author = administrator
  announcement.body = "Welcome students, families, and staff. Please review the timetable and upcoming term dates."
  announcement.audience = :everyone
  announcement.published_at = Time.current
end

fee = school.fee_structures.find_or_initialize_by(name: "Term 1 Tuition", academic_year:)
fee.assign_attributes(amount: 750, due_on: terms.first.starts_on + 30.days)
fee.save!
students.each do |fee_student|
  invoice = fee.invoices.find_or_initialize_by(student: fee_student)
  invoice.assign_attributes(amount: fee.amount, due_on: fee.due_on)
  invoice.save!
end

first_invoice = fee.invoices.find_by!(student: students.first)
first_invoice.update!(discount: 50, discount_reason: "Sibling discount")
payment = first_invoice.payments.find_or_initialize_by(reference: "DEMO-PAYMENT-001")
payment.update!(amount: 250, paid_on: terms.first.starts_on + 7.days, payment_method: :bank_transfer)

comment = students.first.report_card_comments.find_or_initialize_by(term: terms.first, kind: :homeroom_teacher)
comment.assign_attributes(author: administrator, body: "A focused learner who participates well and should keep reading daily.", approved: true)
comment.save!

[
  [ "Excellent progress", "Has made excellent progress this term and should continue the strong effort.", :homeroom_teacher ],
  [ "Good effort", "Has worked consistently this term and is encouraged to participate even more in class.", :homeroom_teacher ],
  [ "Needs more focus", "Can achieve stronger results by improving concentration, completing assignments, and asking for help when needed.", :homeroom_teacher ]
].each do |title, body, kind|
  template = school.report_card_remark_templates.find_or_initialize_by(title:)
  template.update!(body:, kind:, author: administrator, active: true)
end

CourseSection.joins(:classroom).where(classrooms: { school_id: school.id }, term: terms.first).includes(:teachers).find_each.with_index do |course, index|
  teacher = course.teachers.first
  next unless teacher

  entry = TimetableEntry.find_or_initialize_by(course_section: course, weekday: (index % 5) + 1, period: (index % 5) + 1)
  entry.assign_attributes(teacher:, starts_at: Time.zone.parse("08:00") + (entry.period - 1).hours, ends_at: Time.zone.parse("08:45") + (entry.period - 1).hours, room: course.classroom.name)
  entry.save! unless TimetableEntry.where(teacher:, weekday: entry.weekday, period: entry.period).where.not(id: entry.id).exists?
end

puts "Seeded #{school.students.count} students, #{school.classrooms.count} classes, #{school.subjects.count} subjects, and #{Grade.joins(enrollment: :student).where(students: { school_id: school.id }).count} exam results."
puts "Portal accounts: parent1@example.test / Parent123! and student@example.test / Student123!"
