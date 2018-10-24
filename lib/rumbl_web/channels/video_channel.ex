defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel

  alias Rumbl.{Accounts, Multimedia}

  alias RumblWeb.AnnotationView

  def join("videos:" <> video_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Multimedia.get_video!(video_id)

    annotations =
      video
      |> Multimedia.list_annotations(last_seen_id)
      |> Phoenix.View.render_many(AnnotationView, "annotation.json")

    {:ok, %{annotations: annotations}, assign(socket, :video_id, video_id)}
  end

  def handle_in(event, params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  @spec handle_in(
          <<_::112>>,
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()},
          Rumbl.Accounts.User.t(),
          atom() | %{assigns: atom() | %{video_id: any()}}
        ) :: {:reply, :ok | {:error, map()}, atom() | %{assigns: atom() | map()}}
  def handle_in("new_annotation", params, user, socket) do
    case Multimedia.annotate_video(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        # broadcast!(socket, "new_annotation",
        # RumblWeb.AnnotationView.render("annotation.json", %{annotation: annotation})
        # )

        broadcast_annotation(socket, user, annotation)
        # we use start_link because we don't care about the results, and don't
        # want to block any particular message arriving to the channel
        Task.start_link(fn -> compute_additional_info(annotation, socket) end)

        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  defp broadcast_annotation(socket, user, annotation) do
    broadcast!(socket, "new_annotation", %{
      id: annotation.id,
      user: RumblWeb.UserView.render("user.json", %{user: user}),
      body: annotation.body,
      at: annotation.at
    })
  end

  defp compute_additional_info(annotation, socket) do
    for result <- Rumbl.InfoSys.compute(annotation.body, limit: 1, timeout: 10_000) do
      IO.inspect(result)
      backend_user = Accounts.get_user_by(username: result.backend.name())
      attrs = %{url: result.url, body: result.text, at: annotation.at}

      case Multimedia.annotate_video(backend_user, annotation.video_id, attrs) do
        {:ok, info_ann} -> broadcast_annotation(socket, backend_user, info_ann)
        {:error, _changeset} -> :ignore
      end
    end
  end
end
