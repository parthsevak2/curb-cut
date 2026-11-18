/**
 * A door is only offered once it exists. These run the same in an org that
 * has a number and one that does not, because the labels are set per org.
 */
@IsTest
private class CurbCutDoorsTest {

    @IsTest
    static void aFreshInstallOffersOnlyThisPlace() {
        CurbCutDoors.linkOverride = CurbCutDoors.NO_NUMBER;
        CurbCutDoors.inboundOverride = 'inbound-address@example.com';
        System.assertEquals(false, CurbCutDoors.textOpen(), 'the placeholder number is not a door');
        System.assertEquals(false, CurbCutDoors.emailOpen(), 'the placeholder address is not a door');
        System.assertEquals('here', CurbCutDoors.orElsewhere());
    }

    @IsTest
    static void aConnectedNumberOpensText() {
        CurbCutDoors.linkOverride = '+14165550123';
        CurbCutDoors.inboundOverride = 'inbound-address@example.com';
        System.assertEquals(true, CurbCutDoors.textOpen());
        System.assertEquals('here, or by text', CurbCutDoors.orElsewhere());
    }

    @IsTest
    static void anInboundAddressOpensEmail() {
        CurbCutDoors.linkOverride = CurbCutDoors.NO_NUMBER;
        CurbCutDoors.inboundOverride = 'curbcut@abc.apex.salesforce.com';
        System.assertEquals(true, CurbCutDoors.emailOpen());
        System.assertEquals('here, or by email', CurbCutDoors.orElsewhere());
    }

    @IsTest
    static void everyDoorWhenEverythingIsConnected() {
        CurbCutDoors.linkOverride = '+14165550123';
        CurbCutDoors.inboundOverride = 'curbcut@abc.apex.salesforce.com';
        System.assertEquals('here, or by text, or by email', CurbCutDoors.orElsewhere());
    }

    @IsTest
    static void aBlankLabelIsNotADoor() {
        CurbCutDoors.linkOverride = ' ';
        CurbCutDoors.inboundOverride = '';
        System.assertEquals(false, CurbCutDoors.textOpen());
        System.assertEquals(false, CurbCutDoors.emailOpen());
    }

    @IsTest
    static void theLiveLabelsGiveAnAnswerEitherWay() {
        // Whatever this org holds, the helper answers without throwing, and
        // "here" always leads, because this place is always a door.
        System.assert(CurbCutDoors.orElsewhere().startsWith('here'));
    }
}
