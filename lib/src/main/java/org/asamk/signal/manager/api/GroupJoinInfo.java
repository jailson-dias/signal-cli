package org.asamk.signal.manager.api;

public record GroupJoinInfo(
        String title,
        String inviteLinkUrl,
        String avatar,
        int memberCount,
        int revision,
        boolean pendingAdminApproval,
        String description,
        boolean isAnnouncementGroup
) {

    public static GroupJoinInfo from(
        final String title,
        final String inviteLinkUrl,
        final String avatar,
        final int memberCount,
        final int revision,
        final boolean pendingAdminApproval,
        final String description,
        final boolean isAnnouncementGroup
    ) {
        return new GroupJoinInfo(
            title,
            inviteLinkUrl,
            avatar,
            memberCount,
            revision,
            pendingAdminApproval,
            description,
            isAnnouncementGroup
        );
    }
}
