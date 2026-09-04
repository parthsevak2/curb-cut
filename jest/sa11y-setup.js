const { setup } = require('@sa11y/jest');

// Sa11y's matcher defaults to the 64-rule base preset. This project asserts
// against the 100-rule extended preset instead, passed explicitly at each call
// site via jest/a11y-ruleset.js, so the rule set in force is visible in the
// test rather than buried in setup.
setup({ autoCheckOpts: { runAfterEach: false } });
