require 'test_helper'

class SearchAllCodeTest < ActiveSupport::TestCase
  let(:project) { create(:project) }
  let(:widget) { ProjectWidget::SearchAllCode.new(project_id: project.id) }

  describe 'height' do
    it 'should return 130' do
      widget.height.must_equal 130
    end
  end

  describe 'width' do
    it 'should return 350' do
      widget.width.must_equal 350
    end
  end

  describe 'position' do
    it 'should return 7' do
      widget.position.must_equal 7
    end
  end

  describe 'title' do
    it 'should return the title' do
      widget.title.must_equal I18n.t('project_widgets.search_code.title')
    end
  end

  describe 'short_nice_name' do
    it 'should return the short_nice_name' do
      widget.short_nice_name.must_equal I18n.t('project_widgets.search_code.short_nice_name')
    end
  end
end