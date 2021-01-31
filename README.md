# ModelTransporter

Syndicate Rails model updates to your client-side Redux store via Action Cable.

If you have many users viewing the same objects in different sessions, stored in Redux or a similar client-side store, `ModelTransporter` allows updates made by one client to flow to the others instantly. Since clients update models via web requests, `ModelTransporter` batches updates from each request together so that listeners see changes to all related objects at once.

![](https://user-images.githubusercontent.com/952319/106395105-70b11b80-63ce-11eb-9391-61282809d477.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'model_transporter'
```

## Usage

Sync updates for a model via:

```ruby
class MyModel < ApplicationRecord
  notifies_model_updates channel: -> { MyChannel.broadcasting_for(self) }
end
```

The `channel` tells `ModelTransporter` which listeners to notify, and also serves as a grouping key for updates within a single web request. In the above example, if you had a channel defined as:

```ruby
class MyChannel < ApplicationCable::Channel
  def subscribed
    my_model = MyModel.find(params[:id])
    stream_for my_model
  end
end
```

Then any client connected to that channel would receive push updates for changes to that model.

If you had a TodoList app with `TodoList` objects that were shared between users, `Todo`s that belong to `TodoList`s, and `TodoComment`s that belong to `Todo`s, you could set it up as follows to ensure all clients on the same `TodoList` page get real-time updates from other users to stay in sync:

```ruby
class TodoList < ApplicationRecord
  has_many :todos, dependent: :destroy

  notifies_model_updates channel: -> { TodoListChannel.broadcasting_for(self) }
end

class Todo < ApplicationRecord
  belongs_to :todo_list
  has_many :todo_comments, dependent: :destroy

  notifies_model_updates channel: -> { TodoListChannel.broadcasting_for(todo_list) }
end

class TodoComment < ApplicationRecord
  belongs_to :todo

  notifies_model_updates channel: -> { TodoListChannel.broadcasting_for(todo.todo_list) }
end
```

Since all 3 objects use the same parent `TodoList` object, any request that updates one or more of these objects at the same time, e.g. deleting a `Todo` and its dependent comments, would batch all of those changes and send them to everyone listening on the `TodoListChannel` for that `TodoList`.

## Payload format

Payloads follow a simple standard format:

```
{
  type: 'server_event/MODEL_UPDATES',
  actor_id: ACTOR_ID,
  {
    creates: {
      MODEL_NAME: {
        MODEL_ID: MODEL_JSON
      },
      MODEL_2_NAME: { ... }
    }
    updates: {
      MODEL_NAME: {
        MODEL_ID: MODEL_JSON
      },
      MODEL_2_NAME: { ... }
    }
    deletes: {
      MODEL_NAME: {
        MODEL_ID: {}
      },
      MODEL_2_NAME: { ... }
    }
  }
}
```

`ModelTransporter` simply sends these messages, it is your job to handle them on the client side in the way that makes sense, e.g. by objects in your Redux store.

## Configuration options

```ruby
ModelTransporter.configure do |config|
  config.actor = :current_user
  config.push_adapter = MyPushAdapter.new
end
```

- `actor`: `ModelTransporter` includes an `actor_id` in message payloads, which can be useful if you want to determine who triggered a model update. If you have a controller method called `current_user`, you can set `actor` equal to `:current_user`, and `actor_id` in transporter payloads will get set to that user
- `push_adapter`: by default `ModelTransporter` assumes you want to send updates via `ActionCable`. If you want to send updates in another way, e.g. something like `Pusher`, set a custom `push_adapter` to anything that responds to `push_update(channel, message)`.

## Run the specs

`rake spec`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
