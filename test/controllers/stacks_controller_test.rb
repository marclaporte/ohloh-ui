require 'test_helper'

class StacksControllerTest < ActionController::TestCase
  # index action
  it 'index should not require a current user' do
    stack = create(:stack)
    login_as nil
    get :index, account_id: stack.account
    must_respond_with :ok
  end

  it 'index should display for users with no stacks' do
    get :index, account_id: create(:account)
    must_respond_with :ok
  end

  it 'index should gracefully handle non-existant users' do
    get :index, account_id: 'i_am_one_big_teapot'
    must_respond_with :not_found
  end

  it 'index should gracefully handle disabled users' do
    get :index, account_id: create(:disabled_account)
    must_respond_with :not_found
  end

  it 'index should gracefully handle spammers' do
    get :index, account_id: create(:spammer)
    must_respond_with :not_found
  end

  it 'index should gracefully handle unactivated users' do
    get :index, account_id: create(:unactivated)
    must_respond_with :not_found
  end

  it 'index should display when the stack has no projects associated with it' do
    stack = create(:stack, title: 'i_am_there')
    login_as stack.account
    get :index, account_id: stack.account
    must_respond_with :ok
    response.body.must_match stack.title
  end

  it 'index should display when the stack has projects associated with it' do
    stack = create(:stack, title: 'i_am_there')
    create(:stack_entry, stack: stack)
    login_as stack.account
    get :index, account_id: stack.account
    must_respond_with :ok
    response.body.must_match stack.title
  end

  it 'index should display when the stack has projects with no logos associated with it' do
    stack = create(:stack, title: 'i_am_there')
    create(:stack_entry, stack: stack, project: create(:project, logo: nil))
    login_as stack.account
    get :index, account_id: stack.account
    must_respond_with :ok
    response.body.must_match stack.title
  end

  it 'index should not display deleted stacks' do
    stack = create(:stack, title: 'i_am_deleted')
    stack.destroy
    login_as stack.account
    get :index, account_id: stack.account
    must_respond_with :ok
    response.body.wont_match stack.title
  end

  # show action
  it 'show should not require a current user' do
    stack = create(:stack)
    login_as nil
    get :show, id: stack
    must_respond_with :ok
  end

  it 'show should return 404 for disabled users stacks' do
    stack = create(:stack, account: create(:disabled_account))
    login_as nil
    get :show, id: stack
    must_respond_with :not_found
  end

  it 'show should offer edit links to stack owner' do
    stack = create(:stack)
    login_as stack.account
    get :show, id: stack
    must_respond_with :ok
    response.body.must_match I18n.t('stacks.edit_in_place')
  end

  it 'show should not offer edit links to unlogged user' do
    stack = create(:stack)
    login_as nil
    get :show, id: stack
    must_respond_with :ok
    response.body.wont_match I18n.t('stacks.edit_in_place')
  end

  it 'show should not offer edit links to other users' do
    stack = create(:stack)
    login_as create(:account)
    get :show, id: stack
    must_respond_with :ok
    response.body.wont_match I18n.t('stacks.edit_in_place')
  end

  it 'show should star ratings for projects' do
    stack = create(:stack)
    create(:stack_entry, stack: stack, project: create(:project, rating_average: 0))
    create(:stack_entry, stack: stack, project: create(:project, rating_average: 2.5))
    create(:stack_entry, stack: stack, project: create(:project, rating_average: 5))
    login_as stack.account
    get :show, id: stack
    must_respond_with :ok
    response.body.must_match 'rating_stars'
  end

  it 'show should support format: json' do
    stack = create(:stack)
    login_as nil
    get :show, id: stack, format: :json
    must_respond_with :ok
    resp = JSON.parse(response.body)
    resp['title'].must_equal stack.title
    resp['description'].must_equal stack.description
  end

  # create action
  it 'create should require a current user' do
    login_as nil
    post :create
    must_respond_with :unauthorized
  end

  it 'create should require a current user' do
    account = create(:account)
    login_as account
    post :create
    must_respond_with 302
    Stack.where(account_id: account.id).count.must_equal 1
  end

  it 'create should gracefully handle save errors' do
    login_as create(:account)
    Stack.any_instance.expects(:save).returns false
    post :create
    must_respond_with 302
  end

  # update action
  it 'update should require a current user' do
    login_as nil
    put :update, id: create(:stack), stack: { title: 'Best Stack EVAR!' }
    must_respond_with :unauthorized
  end

  it 'update should not work for wrong user' do
    stack = create(:stack, title: 'original')
    login_as create(:account)
    put :update, id: stack, stack: { title: 'changed' }
    must_respond_with :not_found
    stack.reload.title.must_equal 'original'
  end

  it 'update should work for owner changing title' do
    stack = create(:stack, title: 'original')
    login_as stack.account
    put :update, id: stack, stack: { title: 'changed' }
    must_respond_with :ok
    stack.reload.title.must_equal 'changed'
  end

  it 'update should work for owner changing description' do
    stack = create(:stack, description: 'original')
    login_as stack.account
    put :update, id: stack, stack: { description: 'changed' }
    must_respond_with :ok
    stack.reload.description.must_equal 'changed'
  end

  it 'update should gracefully handle errors' do
    stack = create(:stack, description: 'original')
    login_as stack.account
    Stack.any_instance.expects(:update_attributes).returns false
    put :update, id: stack, stack: { description: 'changed' }
    must_respond_with :unprocessable_entity
  end

  # destroy action
  it 'destroy should require a current user' do
    login_as nil
    delete :destroy, id: create(:stack)
    must_respond_with :unauthorized
  end

  it 'destroy should not destroy stack owned by someone else' do
    stack = create(:stack)
    login_as create(:account)
    delete :destroy, id: stack
    must_respond_with :not_found
    stack.reload.deleted_at.must_equal nil
  end

  it 'destroy should destroy stack' do
    stack = create(:stack)
    login_as stack.account
    delete :destroy, id: stack
    must_respond_with 200
    Stack.where(id: stack.id).count.must_equal 0
  end

  it 'destroy should gracefully handle errors' do
    stack = create(:stack)
    login_as stack.account
    Stack.any_instance.expects(:destroy).returns false
    delete :destroy, id: stack
    must_respond_with :unprocessable_entity
  end
end
