defmodule OpencC2TestWeb.RunScriptLive do
  use Phoenix.LiveView

  import OpencC2TestWeb.CoreComponents
  alias OpencC2Test.TestScript

  require Logger

  def mount(_param, _session, socket) do
    # after calling the changeset call to_form
    {:ok, assign(socket, form: to_form(TestScript.change_script(%TestScript{})))}
  end

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="left-[40rem] fixed inset-y-0 right-0 z-0 hidden lg:block xl:left-[50rem] mt-20">
      <div class="container mx-auto">
        <.form class="mt-20 w-3/4" for={@form} phx-change="validate" phx-submit="save">
          <div class="mb-4">
            <.input
            type="select"
            field={@form[:device]}
            options={[TwinklyMaha: "twinklymaha"]}
            prompt="Select project"
            label="Which device are you testing?"
            />
          </div>

          <div class="mb-3">
            <.input
            type="select"
            field={@form[:broker]}
            options={[
              emqx_broker: "emqx",
              HiveMQ_broker: "hivemq"
            ]}
            prompt="Select broker"
            label="Which broker do you want to use?"
            />
          </div>

          <div class="mb-3">
            <.input
            type="select"
            field={@form[:command]}
            options={[
              Turn_led_on: "turn_led_on",
              Turn_led_off: "turn_led_off",
              Query_profile: "query_profile",
              Query_sbom: "query_sbom"
            ]}
            prompt="Select command"
            label="What command do you want to send?"
            />
          </div>

          <div class="mt-2">
            <.button type="submit" class="bg-indigo-500 w-full">Run</.button>
          </div>
        </.form>
      </div>
    </div>

    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32 mt-20">
      <div class="mx-auto max-w-xl lg:mx-0">
        <p class="text-[2rem] mt-4 font-semibold text-indigo-900">
          Welcome to the new interface for TwinklyMaha.
        </p>
        <p class="mt-4 text-indigo-600">
          To ensure that you have a smooth experience,
          we created this as your primary way to interact with TwinklyMaha.
        </p>
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"test_script" => params}, socket) do
    form =
      %TestScript{}
      |> TestScript.change_script(params)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"test_script" => params}, socket) do
    Logger.info("Button Clicked")
    
    publish_message(params)

    Logger.info("message is published")

    {:noreply, put_flash(socket, :info, "Successful")}
  end

  defp publish_message(%{"command" => "query_profile"}) do
    %{
      "action" => "query",
      "target" => %{"features" => ["profiles"]},
      "args" => %{"response_requested" => "complete"},
      "command_id" => "randomcommandid"
    }
    |> Jason.encode!()
    |> Emqtt.publish()
  end

  defp publish_message(%{"command" => command})
       when command == "turn_led_on" or command == "turn_led_off" do
    color =
      case command do
        "turn_led_on" -> "on"
        "turn_led_off" -> "off"
      end

    %{
      "action" => "set",
      "args" => %{"response_requested" => "complete"},
      "target" => %{"led" => color}
    }
    |> Jason.encode!()
    |> Emqtt.publish()
  end

  defp publish_message(params) do
    Logger.info("commands not matching")
  end
end
