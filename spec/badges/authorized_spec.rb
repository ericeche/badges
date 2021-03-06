require File.dirname(__FILE__) + '/../spec_helper'

describe Badges::Authorized do

  before(:each) do 
    engine.storage.roles =  { 'anonymous' =>['view'],
                'member'    =>['view','edit'],
                'admin'     =>['view','edit','delete'],
                'model_admin' =>['twiddle'] }
                
    engine.storage.by_roles = {
      '1' => [{:role=>'admin'}, {:role=>'member'}],
      '2' => [{:role=>'admin', :on=>{:class=>'Account', :id=>1}}, {:role=>'member'}],
      '3' => [{:role=>'admin', :on=>{:class=>'Account'}}, {:role=>'member'}]
    }

    engine.storage.on_roles = {
      '1' => [{:role=>'admin', :by=>{:class=>'User', :id=>2}}]
    }
  end

  it "adds methods to user class" do
    User.should respond_to(:authorized)
  end
  
  it "can declare a role on a class based on a block" do
    User.class_eval do
      has_role(:model_admin, Account) {|user, account| account.owner == user}
    end

    User.badges_model_role_checks.keys.size.should eql(1)
    User.badges_model_role_checks['Account'].size.should eql(1)

    User.class_eval do
      has_role(:model_member, Account) {|user, account| account.id == user.id}
    end

    User.badges_model_role_checks.keys.size.should eql(1)
    User.badges_model_role_checks['Account'].size.should eql(2)

    # puts "User.badges_model_role_checks: #{User.badges_model_role_checks.inspect}"

    user = User.new(5)
    account = Account.new(1)
    user.should_not have_privilege('twiddle', account)

    account.owner = user
    user.should have_privilege('twiddle', account)
    
  end

  it "adds methods to user instances" do
    User.new.should respond_to(:has_privilege?)
  end
  
  it "returns a list of authorizations by the authorized" do
    @user = User.new(2)
    @user.authorizations_by.should == [Badges::Authorization.new(:admin, @user, Account.new(1)), Badges::Authorization.new(:member, @user)]
  end
  
  it "grants a role" do
    @user = User.new(4)
    @user.authorizations_by.should == []
    @user.grant_role(:super_user)
    @user.roles_on.should == [:super_user]
  end

  it "revokes a role" do
    @user = User.new(1)
    @user.roles_on.should == [:admin, :member]
    @user.revoke_role(:admin)
    @user.roles_on.should == [:member]
  end
  
  it "has privilege from global role" do
    User.new(1).should have_privilege('edit')
  end
  
  it "returns roles" do
    User.new(1).roles_on.should == [:admin, :member]
    User.new(1).roles_on(Account.new(1)).should == []

    User.new(2).roles_on.should == [:member]
    User.new(2).roles_on(Account.new(1)).should == [:admin]

    User.new(3).roles_on.should == [:member]
    User.new(3).roles_on(Account).should == [:admin]
  end
  

  it "has privilege from role on class" do
    User.new(3).should have_privilege('delete', Account)
  end

# it "has privilege from role on object" do
# end
# 

  it "has role on authorizable" do
    User.new(2).should have_role(:admin, Account.new(1))
  end
  
end
