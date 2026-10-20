class PagesController < PublicPagesController
  include HtmlRequestsOnly

  def show
    render template: "pages/#{params[:page]}"
  end
end
