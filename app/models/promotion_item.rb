class PromotionItem < ApplicationRecord
  belongs_to :promotion_batch
  belongs_to :student
  belongs_to :source_enrollment, class_name: "Enrollment"
  belongs_to :destination_enrollment, class_name: "Enrollment", optional: true
end
