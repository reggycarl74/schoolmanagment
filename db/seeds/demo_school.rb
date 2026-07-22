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

lesson_content = {
  "MATH" => [
    {
      topic: "Equivalent fractions and number relationships",
      objectives: "Identify equivalent fractions.\nGenerate equivalent fractions using multiplication and division.\nExplain solutions using models.",
      materials: "Fraction strips, number cards, mini whiteboards, learner workbook",
      content: "Begin with a fraction-strip demonstration and review numerator and denominator. Model how multiplying or dividing both parts of a fraction by the same number creates an equivalent fraction. Learners then work in pairs to match fraction cards before completing guided and independent practice.",
      homework: "Complete five equivalent-fraction questions and draw a model for two answers."
    },
    {
      topic: "Comparing and ordering fractions",
      objectives: "Compare fractions with different denominators.\nOrder a set of fractions from smallest to largest.\nJustify comparisons using a common denominator or a number line.",
      materials: "Fraction strips, number line poster, comparison cards, learner workbook",
      content: "Review equivalent fractions from the previous lesson, then model finding a common denominator to compare two fractions. Learners place fraction cards on a class number line, discuss disagreements, and practise ordering sets of three or four fractions independently.",
      homework: "Order two sets of fractions from smallest to largest and explain one comparison in writing."
    },
    {
      topic: "Adding and subtracting fractions with like denominators",
      objectives: "Add and subtract fractions that share a denominator.\nRepresent fraction addition and subtraction using models.\nSolve simple word problems involving like fractions.",
      materials: "Fraction strips, worked-example poster, learner workbook",
      content: "Model addition and subtraction of like fractions using fraction strips, emphasising that the denominator stays the same. Learners complete guided examples on mini whiteboards before solving word problems in pairs and independently.",
      homework: "Solve four addition and subtraction fraction problems, showing a model for one."
    },
    {
      topic: "Solving word problems with fractions",
      objectives: "Interpret word problems involving fractions.\nChoose an appropriate strategy to solve multi-step fraction problems.\nCheck answers for reasonableness.",
      materials: "Word-problem cards, learner workbook, mini whiteboards",
      content: "Read through a worked word problem together, highlighting key information and the operation needed. Learners work in small groups to solve a set of word-problem cards, then present one solution strategy to the class before independent practice.",
      homework: "Complete three fraction word problems and check each answer for reasonableness."
    }
  ],
  "ENG" => [
    {
      topic: "Writing clear descriptive paragraphs",
      objectives: "Recognize the parts of a paragraph.\nUse sensory vocabulary and precise adjectives.\nDraft and revise a coherent descriptive paragraph.",
      materials: "Picture prompts, vocabulary cards, sample paragraph, exercise books",
      content: "Read and discuss a model paragraph, identifying its topic sentence, supporting details, and conclusion. Build a class word bank from a picture prompt. Learners plan, draft, peer-review, and improve one descriptive paragraph.",
      homework: "Revise the class paragraph and write a second paragraph describing a familiar place."
    },
    {
      topic: "Planning and drafting a personal narrative",
      objectives: "Sequence events in a personal narrative.\nUse time-order transition words.\nDraft an opening that engages the reader.",
      materials: "Story-map templates, sample narrative, exercise books",
      content: "Discuss the structure of a personal narrative using a story map. Model an engaging opening sentence, then learners plan their own narrative on a story-map template before drafting the opening and first event.",
      homework: "Complete the story map and draft the next two events of the narrative."
    },
    {
      topic: "Revising for word choice and sentence variety",
      objectives: "Replace overused words with stronger vocabulary.\nCombine short sentences for variety.\nGive and use peer feedback.",
      materials: "Thesaurus cards, sentence-combining worksheet, draft narratives",
      content: "Review a sample draft and identify repeated or weak words, replacing them using thesaurus cards. Practise combining short, choppy sentences into more varied sentences. Learners revise their own narrative draft with a partner using a feedback checklist.",
      homework: "Revise two paragraphs of the narrative using at least four stronger word choices."
    },
    {
      topic: "Presenting and publishing a finished piece",
      objectives: "Edit writing for spelling, punctuation, and grammar.\nFormat a finished piece for publication.\nRead work aloud with appropriate expression.",
      materials: "Editing checklist, publishing paper or device, exercise books",
      content: "Learners complete a final edit of their narrative using an editing checklist, then copy or type a clean final version. Volunteers read their finished narrative aloud to the class, and peers share specific positive feedback.",
      homework: "Finish publishing the narrative and prepare to read a favourite sentence aloud."
    }
  ],
  "SCI" => [
    {
      topic: "States of matter and changes of state",
      objectives: "Describe solids, liquids, and gases.\nCompare particle arrangements.\nExplain melting, freezing, evaporation, and condensation.",
      materials: "Ice, clear cups, water, chart paper, particle-model cards",
      content: "Use ice and water as an observation activity, then connect the changes learners see to a simple particle model. Groups classify everyday materials and create a diagram showing how heating and cooling cause changes of state.",
      homework: "Record three examples of changes of state observed at home and explain each one."
    },
    {
      topic: "Investigating melting and freezing points",
      objectives: "Predict and test how heating and cooling affect materials.\nRecord observations in a simple table.\nCompare melting behaviour of different materials.",
      materials: "Ice cubes, chocolate pieces, timers, observation sheets",
      content: "Learners predict which of several materials will melt fastest, then test their predictions in small groups and record results in an observation table. The class compares findings and discusses why materials melt at different rates.",
      homework: "Complete the observation table and write one conclusion about melting speed."
    },
    {
      topic: "Evaporation, condensation, and the water cycle",
      objectives: "Explain evaporation and condensation using the particle model.\nDescribe the stages of the water cycle.\nIdentify the water cycle in everyday weather.",
      materials: "Kettle-safety video or images, water-cycle diagram, learner workbook",
      content: "Discuss where puddles and wet clothes go, linking learner ideas to evaporation and condensation. Introduce a labelled water-cycle diagram and trace the stages as a class. Learners label their own diagram and describe each stage in their own words.",
      homework: "Draw and label the water cycle and describe one stage in a full sentence."
    },
    {
      topic: "Applying the particle model to everyday materials",
      objectives: "Classify everyday materials by state.\nExplain why a material changes state using the particle model.\nCommunicate scientific explanations clearly.",
      materials: "Household-item cards, particle-model diagrams, learner workbook",
      content: "Learners sort household-item cards by state of matter, then choose two items and explain, using the particle model, what change of state would occur if heated or cooled. Groups present one explanation to the class.",
      homework: "Choose two materials at home and explain a change of state each could undergo."
    }
  ],
  "SOC" => [
    {
      topic: "Community leadership and responsible citizenship",
      objectives: "Identify community leaders and their responsibilities.\nExplain ways citizens support their community.\nEvaluate solutions to a local community problem.",
      materials: "Community map, role cards, scenario sheets, chart paper",
      content: "Discuss leadership roles learners know in their communities. Groups use scenario cards to propose responsible solutions to community problems, identify who should help, and present their recommendations to the class.",
      homework: "Interview an adult about one community responsibility and summarize the response."
    },
    {
      topic: "Rights and responsibilities of citizens",
      objectives: "Distinguish between a right and a responsibility.\nExplain why rights come with responsibilities.\nGive examples of responsible citizenship at school and home.",
      materials: "Rights-and-responsibilities cards, chart paper, learner workbook",
      content: "Sort example cards into rights and responsibilities as a class, discussing any disagreements. Learners work in pairs to match each right with a related responsibility and give a real-life example from school or home.",
      homework: "List three rights and a matching responsibility for each, with a school example."
    },
    {
      topic: "How local government solves community problems",
      objectives: "Describe the role of local government.\nExplain how community problems are reported and addressed.\nIdentify services local government provides.",
      materials: "Local-government diagram, service cards, chart paper",
      content: "Introduce the structure of local government using a simple diagram, then discuss services it provides such as waste collection and road repair. Groups match community problems to the service that could address them and explain their reasoning.",
      homework: "Identify one local service used at home and describe what it provides."
    },
    {
      topic: "Presenting a community action plan",
      objectives: "Design a simple action plan for a community problem.\nAssign realistic steps and responsibilities.\nPresent a plan clearly to an audience.",
      materials: "Action-plan template, chart paper, markers",
      content: "Groups choose a community problem discussed earlier and complete an action-plan template, outlining steps, who is responsible, and expected outcomes. Each group presents its plan to the class and answers questions from peers.",
      homework: "Write one paragraph explaining how you could help carry out your group's action plan."
    }
  ],
  "ICT" => [
    {
      topic: "Digital safety and strong passwords",
      objectives: "Recognize personal information that must stay private.\nCreate strong and memorable passwords.\nRespond safely to suspicious messages and links.",
      materials: "Safety-scenario cards, projector, password checklist, learner workbook",
      content: "Review examples of personal and public information. Demonstrate the features of a strong password without sharing real passwords. Learners rotate through safety scenarios and decide the safest action for each situation.",
      homework: "Create a five-point digital-safety poster for display in class."
    },
    {
      topic: "Recognizing scams and phishing attempts",
      objectives: "Identify common signs of a scam or phishing message.\nExplain why scams try to create urgency.\nDescribe the correct response to a suspicious message.",
      materials: "Sample message cards, projector, learner workbook",
      content: "Examine sample messages together and highlight warning signs such as urgent requests, spelling errors, and unfamiliar links. Learners sort message cards into safe and suspicious, then explain the correct action for each suspicious example.",
      homework: "Find or recall one suspicious message and list two warning signs it showed."
    },
    {
      topic: "Responsible use of chat and shared content",
      objectives: "Explain expectations for respectful online communication.\nDescribe how to think before sharing content.\nIdentify steps to take if online behaviour feels unsafe.",
      materials: "Scenario cards, class online-conduct chart, learner workbook",
      content: "Discuss what respectful communication looks like online, then review a class online-conduct chart together. Learners work through scenario cards involving group chats and shared content, deciding the responsible response and who to tell if something feels unsafe.",
      homework: "Write two class rules for respectful online communication and explain why each matters."
    },
    {
      topic: "Creating a class digital-safety guide",
      objectives: "Summarize key digital-safety practices learned this unit.\nOrganize advice for a younger audience.\nCollaborate to produce a shared class resource.",
      materials: "Poster paper or slides, markers, notes from previous lessons",
      content: "Learners review notes from the unit and work in groups to summarize the most important digital-safety advice. Each group designs one page or slide of a class digital-safety guide aimed at younger learners, then the class combines pages into a shared resource.",
      homework: "Bring one additional digital-safety tip to add to the class guide next lesson."
    }
  ]
}

seeded_lesson_plans = 0
CourseSection.joins(:classroom).where(classrooms: { school_id: school.id }, term: terms.first).includes(:subject, :teachers).find_each.with_index do |course, index|
  teacher = course.teachers.first
  next unless teacher

  lessons = lesson_content.fetch(course.subject.code)
  day_offset = index % 5

  lessons.each_with_index do |details, week|
    lesson_date = terms.first.starts_on + 7.days + (week * 7).days + day_offset.days
    status = case week
    when 0, 1 then :taught
    when 2 then :ready
    else :draft
    end

    plan = course.lesson_notes.find_or_initialize_by(teacher:, lesson_date:)
    plan.assign_attributes(
      topic: details[:topic],
      objectives: details[:objectives],
      materials: details[:materials],
      content: details[:content],
      homework: details[:homework],
      starts_at: Time.zone.parse("08:00") + (week % 3).hours,
      duration_minutes: 45,
      status:
    )
    plan.save!
    seeded_lesson_plans += 1
  end
end

CourseSection.joins(:classroom).where(classrooms: { school_id: school.id }, term: terms.first).includes(:teachers).find_each.with_index do |course, index|
  teacher = course.teachers.first
  next unless teacher

  entry = TimetableEntry.find_or_initialize_by(course_section: course, weekday: (index % 5) + 1, period: (index % 5) + 1)
  entry.assign_attributes(teacher:, starts_at: Time.zone.parse("08:00") + (entry.period - 1).hours, ends_at: Time.zone.parse("08:45") + (entry.period - 1).hours, room: course.classroom.name)
  entry.save! unless TimetableEntry.where(teacher:, weekday: entry.weekday, period: entry.period).where.not(id: entry.id).exists?
end

puts "Seeded #{school.students.count} students, #{school.classrooms.count} classes, #{school.subjects.count} subjects, and #{Grade.joins(enrollment: :student).where(students: { school_id: school.id }).count} exam results."
puts "Seeded #{seeded_lesson_plans} lesson notes and plans across #{teachers.count} teachers."
puts "Portal accounts: parent1@example.test / Parent123! and student@example.test / Student123!"
