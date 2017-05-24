defmodule LiveStory.Web.PostView do
  use LiveStory.Web, :view

  @spec upvoted_class(button_state :: binary, upvote_state :: boolean) :: binary
  def upvoted_class("upvoted", true), do: ""
  def upvoted_class("upvoted", nil), do: "hidden "
  def upvoted_class("not_upvoted", true), do: "hidden "
  def upvoted_class("not_upvoted", nil), do: ""

  def root_path(path) do
    LiveStory.Stories.root_path(path)
  end

  # Avoid fail on less than 3 posts by doing different matches
  # Text duplication here is unavoidable.
  def welcome(true, conn, [post1, post2, post3 | _tail]) do
    "Latest top stories are #{link_post conn, post1}, #{link_post conn, post2} and #{link_post conn, post2}. Help edit them."
  end
  def welcome(true, conn, [post1, post2]) do
    "Latest top stories are #{link_post conn, post1} and #{link_post conn, post2}. Help edit them."
  end
  def welcome(true, conn, [post1]) do
    "The latest top story is #{link_post conn, post1}. Help edit it."
  end
  def welcome(_, conn, _posts) do
    ""
  end

  defp link_post(conn, post) do
    {:safe, link} = link post.title, to: post_path(conn, :show, post)
    link
  end

  def topic_select(topics) do
    Enum.map(topics, &{&1.name, &1.id})
  end
end
