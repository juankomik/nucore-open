require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service", :aggregate_failures do
  include RSpec::Matchers.clone # Give RSpec's `all` precedence over Capybara's

  let!(:service) { FactoryGirl.create(:setup_service) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { service.facility }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base.first, product: service) }
  let(:user) { FactoryGirl.create(:user) }
  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }

  before do
    login_as user
  end

  describe "submission form" do
    let(:quantity) { 5 }
    let(:customer_id_selector) { ".nested_sanger_sequencing_submission_samples input[type=text]" }
    let(:cart_quantity_selector) { ".edit_order input[type=text]" }
    before do
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      find(cart_quantity_selector).set(quantity.to_s)
      click_button "Update"
      click_link "Complete Online Order Form"
    end

    it "sets up the right number of text boxes" do
      expect(page).to have_css(customer_id_selector, count: 5)
    end

    it "has prefilled values in the text boxes with unique four digit numbers" do
      values = page.all(customer_id_selector).map(&:value)
      expect(values).to all(match(/\A\d{4}\z/))
      expect(values.uniq).to eq(values)
    end

    it "saves the form" do
      page.first(customer_id_selector).set("TEST123")
      click_button "Save Submission"
      expect(SangerSequencing::Sample.pluck(:customer_sample_id)).to include("TEST123")
      expect(SangerSequencing::Sample.count).to eq(5)
    end

    describe "adding/removing more fields", :js do
      it "adds fields" do
        page.click_link "Add"
        expect(page).to have_css("#{customer_id_selector}:enabled", count: 6)
        expect(page.all(customer_id_selector).last.value).to match(/\A\d{4}\z/)
        click_button "Save Submission"
        expect(SangerSequencing::Sample.count).to eq(6)

        # back on the cart
        expect(page.find(cart_quantity_selector).value).to eq("6")
      end

      it "can remove fields" do
        page.all(:link, "Remove").first.click
        expect(page).to have_css(customer_id_selector, count: 4)
        click_button "Save Submission"
        expect(SangerSequencing::Sample.count).to eq(4)

        # back on the cart
        expect(page.find(cart_quantity_selector).value).to eq("4")
      end
    end

    describe "blank fields" do
      it "does not allow submitting a blank value" do
        page.first(customer_id_selector).set("")
        click_button "Save Submission"
        expect(page.first(customer_id_selector).value).to be_blank
        expect(SangerSequencing::Sample.pluck(:customer_sample_id)).not_to include("")
      end

      it "deletes blanks from the end" do
        page.all(customer_id_selector).last.set("")
        click_button "Save Submission"
        expect(SangerSequencing::Sample.count).to eq(4)
      end

      it "does not save if they are all blank" do
        page.all(customer_id_selector).each { |textbox| textbox.set("") }
        click_button "Save Submission"
        expect(page).to have_content("You must have at least one sample")
      end
    end

    describe "and more samples were created in another page" do
      before do
        SangerSequencing::Submission.first.create_samples!(5)
      end

      it "does removes the extra ones" do
        page.all(customer_id_selector).each_with_index { |textbox, i| textbox.set(i + 1) }
        click_button "Save Submission"
        expect(SangerSequencing::Sample.pluck(:customer_sample_id)).to eq(%w(1 2 3 4 5))
      end
    end

    describe "saving and returning to the form" do
      before do
        page.first(customer_id_selector).set("TEST123")
        click_button "Save Submission"
      end

      it "returns to the form" do
        click_link "Edit Online Order Form"
        expect(page.first(customer_id_selector).value).to eq("TEST123")
      end
    end
  end
end