defmodule LiveStory.Web.PostController do
  use LiveStory.Web, :controller

  alias LiveStory.Stories

  plug Guardian.Plug.EnsureAuthenticated, [handler: ErrorHandler] when not action in [:index, :show]
  plug :set_user
  plug :set_post when action in [:fork, :show, :edit, :update, :delete]
  plug :set_topics when action in [:index, :new, :edit, :fork]
  plug :check_same_user when action in [:edit, :update, :delete]

  @default_topic "random"

  def index(conn, _params) do
    posts = Stories.list_posts
    post_ids = Enum.map(posts, &(&1.id))
    post_paths = Enum.map(posts, &(&1.path))
    upvotes = Stories.list_user_post_upvotes(conn.assigns.user, post_ids)
    forks_count = Stories.count_forks(post_paths)
    render(conn, "index.html",
      posts: posts,
      upvotes: upvotes,
      forks_count: forks_count,
      user: conn.assigns.user
    )
  end

  #Udia Web Controllers
  #https://github.com/udia-software/udia/tree/master/lib/udia/web/controllers

  #Order posts by newest first:
  #http://stackoverflow.com/questions/42843358/phoenix-application-posts-show-newest-first

#   def index(conn, _params) do
#     posts = Repo.all(from Post, order_by: [desc: :inserted_at])
#     render(conn, "index.html", posts: posts)
#   end

  def new(conn, _params) do
    default_topic = Stories.get_topic!(@default_topic)
    changeset = Stories.change_post(
      %LiveStory.Stories.Post{},
      %{topic_id: default_topic.id}
    )
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    case Stories.create_post(post_params, conn.assigns.user) do
      {:ok, post} ->
        conn
        # |> put_flash(:info, "Post created! ヽ(´▽`)/")
        |> redirect(to: post_path(conn, :show, post))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def fork(conn, _params) do
    forked_post = Stories.create_forked_post(conn.assigns.post, conn.assigns.user)
    changeset = Stories.change_post(forked_post, %{})
    render(conn, "edit.html", post: forked_post, changeset: changeset)
  end



  # Old Forked post code
  # def fork(conn, %{"id" => id}) do
  #     post = Stories.get_post!(id)
  #     forked_post = post
  #       {:ok, forked_post} ->
  #         conn
  #         |> put_flash(:info, :"You just forked that post.")
  #         |> redirect(to: post_path(conn, :show, post))
  #       {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # # end

  def show(conn, _params) do
    post = conn.assigns.post
    comments = Stories.post_comments(post.id)
    comment_ids = Enum.map(comments, &(&1.id))
    upvotes = Stories.list_user_comment_upvotes(conn.assigns.user, comment_ids)
    comment_changeset = if conn.assigns.user do
      Stories.new_post_comment(post, %{
        user_name: conn.assigns.user.username
      })
    end
    render(conn, "show.html",
      post: post,
      comments: comments,
      comment_changeset: comment_changeset,
      upvotes: upvotes
    )
  end

  def edit(conn, _params) do
    changeset = Stories.change_post(conn.assigns.post)
    render(conn, "edit.html", post: conn.assigns.post, changeset: changeset)
  end

  def update(conn, %{"post" => post_params}) do
    case Stories.update_post(conn.assigns.post, post_params) do
      {:ok, post} ->
        conn
     #  |> put_flash(:info, "Post created/updated. Ψ ")
        |> redirect(to: post_path(conn, :show, post))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", post: conn.assigns.post, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    {:ok, _post} = Stories.delete_post(conn.assigns.post)
    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  defp set_user(conn, _opts) do
    assign(conn, :user, Guardian.Plug.current_resource(conn))
  end

  defp set_post(conn, _opts) do
    %{"id" => id} = conn.params
    assign(conn, :post, Stories.get_post!(id))
  end

  def set_topics(conn, _opts) do
    assign conn, :topics, Stories.list_topics
  end

  defp check_same_user(conn, _opts) do
    if conn.assigns.user.id != conn.assigns.post.user_id do
      conn
      |> put_flash(:error, "This post belongs to another user! You can fork someone else's post, but not edit it.")
      |> redirect(to: post_path(conn, :index))
      |> halt
    else
      conn
    end
  end
end
