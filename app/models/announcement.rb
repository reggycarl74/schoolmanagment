class Announcement < ApplicationRecord
  belongs_to :school
  belongs_to :author, class_name: "User"
  enum :audience, { everyone: 0, staff: 1, parents: 2, students: 3 }
  validates :title, :body, :published_at, presence: true
end
