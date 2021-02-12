# Rails UUID to Integer Primary Keys

So you inherited a Rails app that is currently using UUID’s but now its causing size or speed problems with your app.

Now its time to convert your UUID primary keys back to integer / bigint primary keys, however it is not trivial to do this because all references / belongs_to associations must be kept intact.

I have gone through the hard work of creating a migration that is able to handle this for you mostly automatically.

# Requirements

- All models to convert must inherit from ApplicationRecord
- All `belongs_to` or `has_and_belongs_to_many` must be correctly defined so that reference keys can be located and updated.

# Migration

- [migration.rb](./migration.rb)

# Credits

Created by [Weston Ganger](https://westonganger.com) - [@westonganger](https://github.com/westonganger)
