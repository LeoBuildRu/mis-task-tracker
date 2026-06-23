# With use_transactional_fixtures = true, each example is wrapped in a
# transaction that rolls back, so system tags seeded in before(:suite)
# persist across the whole run. No explicit cleaning is needed here.
