# Getting started

### Install Dependencies
```
bundle install
```
### Migrate the Database
```
rake db:create
rake db:migrate
rake db:reset
rake db:setup
```

# Checks before creating a PR

### Linter
```
bundle exec rubocop
```

### Run Rspec Tests (100% coverage)
```
bundle exec rspec
```

### Run Cucumber Tests
```
bundle exec cucumber
```