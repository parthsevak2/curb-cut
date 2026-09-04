const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

// Sa11y is Salesforce's own accessibility matcher: axe-core driven, with the
// WCAG rule set the platform ships. A failure here is the failure a Salesforce
// accessibility reviewer would see.
module.exports = {
    ...jestConfig,
    setupFilesAfterEnv: [
        ...(jestConfig.setupFilesAfterEnv || []),
        '<rootDir>/jest/sa11y-setup.js',
    ],
    testMatch: ['**/*.a11y.test.js'],
};
