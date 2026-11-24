require "rails_helper"

RSpec.describe "choosing the correct controller to inherit from" do
  let(:teacher) { create(:teacher) }
  let(:admin_user) { create(:admin) }

  shared_examples "not allowing an unauthenticated teacher access" do
    it "does not allow unauthenticated teacher access" do
      get :index
      expect(response).to redirect_to(root_path)
    end
  end

  shared_examples "redirecting an unauthenticated teacher to admin sign in" do
    it "does not allow unauthenticated teacher access" do
      get :index
      expect(response).to redirect_to(sign_in_path)
    end
  end

  shared_examples "allowing an unauthenticated teacher access" do
    it "allows unauthenticated teacher access" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "allowing an authenticated teacher access" do
    it "allows authenticated teacher access" do
      session[:teacher_id] = teacher.id
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "not allowing an authenticated teacher access" do
    it "does not allow authenticated teacher access" do
      session[:teacher_id] = teacher.id
      get :index
      expect(response).to redirect_to(sign_in_path)
    end
  end

  shared_examples "allowing an admin access" do
    it "allows an admin access" do
      session[:admin_id] = admin_user.id
      session[:admin_sign_in_at] = Time.zone.now
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples "not allowing an admin access" do
    it "does not allow an admin access" do
      session[:admin_id] = admin_user.id
      session[:admin_sign_in_at] = Time.zone.now
      get :index
      expect(response).to redirect_to(root_path)
    end
  end

  context "when a controller is a subclass of ApplicationController" do
    controller(ApplicationController) do
      def index
        head :ok
      end
    end

    it "raises an error" do
      expect { get :index }.to raise_error(RuntimeError, "ApplicationController should not be used directly. Use a subclass instead.")
    end
  end

  context "when a controller is a subclass of LoggedInController" do
    controller(LoggedInController) do
      def index
        head :ok
      end
    end

    it_behaves_like "not allowing an unauthenticated teacher access"
    it_behaves_like "allowing an authenticated teacher access"
    it_behaves_like "not allowing an admin access"

    it "allows a teacher signed in under the pre-rename session key access" do
      session[:user_id] = teacher.id
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  context "when a controller is a subclass of AdminController" do
    controller(AdminController) do
      def index
        head :ok
      end
    end

    it_behaves_like "redirecting an unauthenticated teacher to admin sign in"
    it_behaves_like "not allowing an authenticated teacher access"
    it_behaves_like "allowing an admin access"
  end

  context "when a controller is a subclass of PublicPagesController" do
    controller(PublicPagesController) do
      def index
        head :ok
      end
    end

    it_behaves_like "allowing an unauthenticated teacher access"
    it_behaves_like "allowing an authenticated teacher access"
    it_behaves_like "allowing an admin access"
  end

  describe "sessions with NullTeacher in" do
    controller(PublicPagesController) do
      def index
        head :ok
      end
    end

    context "with a NullTeacher set" do
      before do
        session[:teacher_id] = 1
        session[:registration_store] = { current_teacher: NullTeacher.new }
      end

      it "clears out the session" do
        get :index
        expect(session[:teacher_id]).to be_nil
        expect(session[:registration_store]).to be_nil
      end
    end

    context "without a NullTeacher set" do
      before do
        session[:teacher_id] = teacher.id
        session[:registration_store] = { current_teacher: teacher }
      end

      it "does not clear out the session" do
        get :index
        expect(session[:teacher_id]).to eq teacher.id
        expect(session[:registration_store][:current_teacher]).to eq teacher
      end
    end

    context "with a NullTeacher set under the pre-rename key" do
      before do
        session[:user_id] = 1
        session[:registration_store] = { current_user: NullTeacher.new }
      end

      it "clears out the session" do
        get :index
        expect(session[:teacher_id]).to be_nil
        expect(session[:registration_store]).to be_nil
      end
    end
  end

  describe "sessions written with pre-rename keys" do
    controller(PublicPagesController) do
      def index
        head :ok
      end
    end

    before do
      session[:user_id] = teacher.id
      session[:registration_store] = { "current_user_id" => teacher.id, "course_identifier" => "npq-senco" }
    end

    it "moves them to the renamed keys" do
      get :index
      expect(session[:user_id]).to be_nil
      expect(session[:teacher_id]).to eq teacher.id
      expect(session[:registration_store]).to eq("current_teacher_id" => teacher.id, "course_identifier" => "npq-senco")
    end
  end
end
