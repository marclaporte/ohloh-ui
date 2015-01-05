class Project < ActiveRecord::Base
  has_one :permission, as: :target
  belongs_to :logo

  has_many :manages, -> { where(deleted_at: nil, deleted_by: nil) }, as: 'target'
  has_many :managers, through: :manages, source: :account
  has_many :reviews

  scope :from_param, ->(param) { where(url_name: param) }

  acts_as_editable editable_attributes: [:name, :url_name, :logo_id, :organization_id, :best_analysis_id,
                                         :description, :url, :download_url, :tag_list, :missing_source],
                   merge_within: 30.minutes

  def to_param
    url_name
  end

  def active_managers
    Manage.projects.for_target(self).active.to_a.map(&:account)
  end
end
