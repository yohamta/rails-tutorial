require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  
  def setup
    # Clear the number of times mail was sent
    ActionMailer::Base.deliveries.clear
  end
  
  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: {
        user: {
          name: "",
          email: "user@invalid",
          password: "foo",
          password_confirmation: "bar",
      }}
    end
    assert_template 'users/new'
    assert_select "form#new_user[action=?]", signup_path
    assert_select "div#error_explanation"
    assert_select "div.field_with_errors > input#user_name"
  end
  
  test "valid signup information with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {
        user: {
          name: "foo",
          email: "foo@bar.com",
          password: "password",
          password_confirmation: "password",
      }}
    end
    # Assert the number of times mail was sent is 1
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)
    assert_not user.activated?
    # Log in before activate the account
    log_in_as(user)
    assert_not is_logged_in?
    # Activate the account with invalid token
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    # Token is valid but email address is invalid
    get edit_account_activation_path(user.activation_token, email: "wrong")
    assert_not is_logged_in?
    # Valid token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!
    assert_template 'users/show'
    assert is_logged_in?
  end
end
