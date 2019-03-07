defmodule ExOneSignal.Notification do
  alias ExOneSignal.Notification

  defstruct \
    headings: %{},
    contents: %{},
    include_player_ids: [],
    data: %{},
    ios_badgeType: "Increase",
    ios_badgeCount: 0

  def new, do: %Notification{}

  def set_title(%Notification{} = notification, title, language \\ :en)
  when is_bitstring(title) and is_atom(language),
    do: put_in(notification, [Access.key(:headings), language], title)

  def set_body(%Notification{} = notification, body, language \\ :en)
  when is_bitstring(body) and is_atom(language),
    do: put_in(notification, [Access.key(:contents), language], body)

  def add_player(%Notification{include_player_ids: ids} = notification, player_id)
  when is_bitstring(player_id),
    do: %{notification | include_player_ids: [player_id | ids]}

  def add_players(%Notification{include_player_ids: ids} = notification, player_ids)
  when is_list(player_ids),
    do: %{notification | include_player_ids: player_ids ++ ids}

  def add_data(%Notification{} = notification, key, value)
  when is_atom(key) and is_bitstring(value),
    do: put_in(notification, [Access.key(:data), key], value)

  def set_badge_count(%Notification{} = notification, badge_count)
  when is_integer(badge_count),
    do: %{notification | ios_badgeType: "SetTo", ios_badgeCount: badge_count}
end
