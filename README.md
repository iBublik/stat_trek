# StatTrek

![Inspired by](http://www.startrek.com/uploads/assets/db_articles/6ee08d45f7a94d4c6fda9ee84833054a687ddf77.jpg)

This gem provides a simple interface to track statisitcs by your models. It gives you full control of how statistic will be aggregated. It's just a backbone giving common patterns for tracking statistic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stat_trek'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install stat_trek

## Usage

Simply add this line to your model:
`stat_trek :score`

In this example we assume that this line was placed inside `Test` model
It will allow you to run following method on instance of this model: `test.stat_trek(:score, 20)`. 
By default it assumes that you have model named `TestStatistc` (model name + `Statistic` postfix) identified by field `test_id` (lowercased model name + `_id` postfix). Value for this key field will be taken from primary key field of instance, which called `stat_trek` method. Default aggregation strategy is `override`, which simply overrides current statistic `score` value with given one.
All described defaults can be overriden. Simply pass option you want to override at class level definition:
```ruby
class Test < ApplicationRecord
  stat_trek :score, stats_model: MyModelWithStatistic, key_fields: [:user_id, test_slug: :slug], agg_strategy: :accumulate
end
```
The line above will create rule to update `MyModelWithStatistic` model with help of built in `accumulate` strategy.
It also describes non-standard key fields. First is `user_id` and it has no mapping, that means it can't be taken from instance of model that calls statistic update. This key and it's value should be passed as last option when calling `stat_trek` instance method: `test.stat_trek(:score, 20, user_id: 1)`.
The second one is mapping pair `test_slug: :slug` where first element is name of key field in statistics model and last is key field name in model containing the tracking description. So, assuming that `test.slug == 'ruby'`, calling `test.stat_trek(:score, 20, user_id: 1)` will find or create instance of `MyModelWithStatistic` by these attributes `user_id: 1, test_slug: 'ruby'`.

## Aggregation strategies
By default there's two aggregation strategies:
- `override`. Simply replaces current value with new one
- `accumulate`. Adds given value with new one (race-condition free way).

You can define custom aggregations. Just define your class with necessary logic, inherit it from `StatTrek::AggStrategies::Base` and define method `call` in it:
```ruby
class DoubleStrategy < StatTrek::AggStrategies::Base
  def call(stats_instance, _value)
    stats_instance.class.where(
      id: stats_instance.id
    ).update_all("#{field} = #{field} * 2")
  end
end
```
Method `call` accepts 2 arguments - the instance of statistic that will be updated and the given value.
Then you should register your strategy - `StatTrek.config.register_strategy :double, DoubleStrategy`.
And you're good to go:
```ruby
class Test < ApplicationRecord
  stat_trek :score, agg_strategy: :double
end
```

## Guards
Guards is way to prevent your statistic from being updated. By default there's 2 built in guards.

### TimeLimit
This guard stops statistic updating if time limit reached. Assume your `Test` model has field `deadline`, you can write this:
```ruby
class Test < ApplicationRecord
  stat_trek :score, guards: { time_limit: { time_field: :deadline } }
end
```
So tests that reached there's deadline (current time is greater than value in this field) will not touch statistic.

### Throttle
If you want to update your statistic not more than once in 30s, simply write this:
```ruby
class Test < ApplicationRecord
  stat_trek :score, guards: { throttle: { period: 30.seconds } }
end
```
By default this guard uses redis as backend, but you can pass your own backend:
`StatTrek.config.update_guard :throttle, backend: your_backend_here`
Backend should implement 2 methods: `store(key, expiration)` and `exists?(key)`. First one is used to persist information about statistic update, second one is for checking whether we can update same statistic field again.

As with strategies, you can add your own guard. Create class inherited from `StatTrek::Guards::Base` and implement method `call`:
```ruby
class MyGuard < StatTrek::Guards::Base
  def call(model_instance, key_fields)
    model_instance.deleted? || meta[:admin_ids].include?(key_fields[:user_id])
  end
end
```
Then register it: `StatTrek.config.registered_guard :my_guard, MyGuard, admin_ids: Admin.ids`. Last option is hash of metadata that will be passed to guard.

All guards accepts `on_trigger` options, which can be either symbol or proc. This option will be called when guard blocks updating of statistc. If proc is given, the model instance will be passed as param to it. If symbol is given, method with this name will be called on model instance.

## `touch` option
You can specify associations which should update there's statistic too. Let's take as example this structure of project:
```ruby
class Session < ApplicationRecord
  has_many :courses

  stat_trek :score, key_fields: [:user_id, session_id: :id], agg_strategy: :accumulate
end

class Course < ApplicationRecord
  belongs_to :session
  has_many :tests

  stat_trek :score, key_fields: [:user_id, course_id: :id], , agg_strategy: :accumulate, touch: :session
end

class Test < ApplicationRecord
  belongs_to :course

  stat_trek :score, key_fields: [:user_id, test_id: :id], agg_strategy: :accumulate, touch: :course
end
```

When we call `test.stat_trek(:score, 20)` it will update not only test's statistic, but also course's and session's.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/stat_trek. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the StatTrek project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/stat_trek/blob/master/CODE_OF_CONDUCT.md).
