require 'spec_helper'; require 'controller_spec_helper'

describe FacilitiesController do
  render_views

  it "should route" do
    { :get => "/facilities" }.should route_to(:controller => 'facilities', :action => 'index')
    { :get => "/facilities/url_name" }.should route_to(:controller => 'facilities', :action => 'show', :id => 'url_name')
    { :get => "/facilities/url_name/manage" }.should route_to(:controller => 'facilities', :action => 'manage', :id => 'url_name')
  end

  before(:all) { create_users }

  before(:each) do
    @authable = Factory.create(:facility)
  end


  context "new" do

    before(:each) do
      @method=:get
      @action=:new
    end

    it_should_require_login

    it_should_deny :director

    it_should_allow :admin do
      @controller.expects(:init_current_facility).never
      do_request
      response.should be_success
      response.should render_template('facilities/new')
    end

  end


  context "create" do

    before(:each) do
      @method=:post
      @action=:create
      @params={
        :facility => {
          :name => "A New Facility", :abbreviation => "anf", :description => "A boring description",
          :is_active => 1, :url_name => 'anf', :short_description => 'A short boring desc'
        }
      }
    end

    it_should_require_login
  
    it_should_deny_all [ :guest, :director ]

    it_should_allow :admin do
      assigns[:facility].should be_valid
      response.should redirect_to "/facilities/anf/manage"
    end

  end


  context "index" do

    before(:each) do
      @method=:get
      @action=:index
    end
    
    it_should_allow_all [ :admin, :guest ] do
      assigns[:facilities].should == [@authable]
      response.should be_success
      response.should render_template('facilities/index')
    end

  end


  context "manage" do

    before(:each) do
      @method=:get
      @action=:manage
      @params={ :facility_id => @authable.url_name, :id => @authable.url_name }
    end

    it_should_require_login
  
    it_should_deny :guest
  
    it_should_allow :director do
      response.should be_success
      response.should render_template('facilities/manage')
    end

  end


  context "show" do

    before(:each) do
      @method=:get
      @action=:show
      @params={ :id => @authable.url_name }
    end

    it_should_allow_all ([ :guest ] + facility_operators) do
      @controller.current_facility.should == @authable
      response.should be_success
      response.should render_template('facilities/show')
    end
    
  end


  context "list" do

    before(:each) do
      @method=:get
      @action=:list
    end

    it_should_require_login

    it_should_deny :guest

    context "as facility operators" do

      before(:each) do
        @controller.stubs(:current_facility).returns(@authable)
        @controller.expects(:init_current_facility).never
      end

      it_should_allow_all facility_operators do
        assigns(:manageable_facilities).should_not be_nil
        assigns(:facilities).should == [@authable]
        response.should be_success
        response.should render_template('facilities/list')
      end
    end

    context "as administrator" do

      before(:each) do
        @facility2 = Factory.create(:facility)
        @controller.stubs(:current_facility).returns(@authable)
      end
  
      it_should_allow :admin do
        assigns[:manageable_facilities].should == []
        assigns[:facilities].should == [@authable, @facility2]
        response.should be_success
        response.should render_template('facilities/list')
      end
    end

  end

end
