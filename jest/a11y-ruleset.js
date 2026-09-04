const { extended } = require('@sa11y/preset-rules');

/**
 * The rule set these components are held to.
 *
 * extended (100 rules), not the 64-rule base preset, because the rules that
 * only appear in extended are the ones a keyboard and screen reader user
 * actually hits.
 *
 * One rule is removed, and only one. "region" requires every piece of content
 * to sit inside a landmark. That is a property of a page, not of a component
 * mounted on its own in a test, where there is no <main> because there is no
 * page. Landmark structure on the real pages is checked separately by the
 * static accessibility suite that runs against the deployed Visualforce.
 * Removing it here is the difference between a test that is quiet because the
 * code is right and one that is quiet because the rule was never run.
 */
const EXCLUDED = ['region'];

const projectRuleset = {
    ...extended,
    runOnly: {
        ...extended.runOnly,
        values: extended.runOnly.values.filter((r) => !EXCLUDED.includes(r)),
    },
};

module.exports = { projectRuleset, EXCLUDED };
