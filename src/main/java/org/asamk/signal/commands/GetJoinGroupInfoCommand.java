package org.asamk.signal.commands;

import net.sourceforge.argparse4j.inf.Namespace;
import net.sourceforge.argparse4j.inf.Subparser;

import org.asamk.signal.commands.exceptions.CommandException;
import org.asamk.signal.commands.exceptions.IOErrorException;
import org.asamk.signal.commands.exceptions.UserErrorException;
import org.asamk.signal.manager.Manager;
import org.asamk.signal.manager.api.GroupInviteLinkUrl;
import org.asamk.signal.manager.api.InactiveGroupLinkException;
import org.asamk.signal.manager.api.PendingAdminApprovalException;
import org.asamk.signal.output.JsonWriter;
import org.asamk.signal.output.OutputWriter;
import org.asamk.signal.output.PlainTextWriter;
import org.asamk.signal.util.SendMessageResultUtils;
import org.asamk.signal.manager.api.GroupJoinInfo;

import java.io.IOException;
import java.util.Map;

public class GetJoinGroupInfoCommand implements JsonRpcLocalCommand {
    @Override
    public String getName() {
        return "getJoinGroupInfo";
    }

    @Override
    public void attachToSubparser(final Subparser subparser) {
        subparser.help("Get Join group info via an invitation link.");
        subparser.addArgument("--uri").required(true).help("Specify the uri with the group invitation link.");
    }

    @Override
    public void handleCommand(
            final Namespace ns, final Manager m, final OutputWriter outputWriter
    ) throws CommandException {
        final GroupInviteLinkUrl linkUrl;
        var uri = ns.getString("uri");
        try {
            linkUrl = GroupInviteLinkUrl.fromUri(uri);
        } catch (GroupInviteLinkUrl.InvalidGroupLinkException e) {
            throw new UserErrorException("Group link is invalid: " + e.getMessage());
        } catch (GroupInviteLinkUrl.UnknownGroupLinkVersionException e) {
            throw new UserErrorException("Group link was created with an incompatible version: " + e.getMessage());
        }

        if (linkUrl == null) {
            throw new UserErrorException("Link is not a signal group invitation link");
        }

        try {
            final GroupJoinInfo groupJoinInfo = m.getGroupJoinInfo(linkUrl);
            switch (outputWriter) {
                case JsonWriter writer -> {
                    writer.write(
                        Map.of(
                            "title",
                            groupJoinInfo.title(),
                            "inviteLinkUrl",
                            groupJoinInfo.inviteLinkUrl(),
                            "avatar",
                            groupJoinInfo.avatar(),
                            "memberCount",
                            groupJoinInfo.memberCount(),
                            "revision",
                            groupJoinInfo.revision(),
                            "pendingAdminApproval",
                            groupJoinInfo.pendingAdminApproval(),
                            "description",
                            groupJoinInfo.description(),
                            "isAnnouncementGroup",
                            groupJoinInfo.isAnnouncementGroup()
                        )
                    );
                }
                case PlainTextWriter writer -> {
                    writer.println("title: {}", groupJoinInfo.title());
                    writer.println("inviteLinkUrl: {}", groupJoinInfo.inviteLinkUrl());
                    writer.println("avatar: {}", groupJoinInfo.avatar());
                    writer.println("memberCount: {}", groupJoinInfo.memberCount());
                    writer.println("revision: {}", groupJoinInfo.revision());
                    writer.println("pendingAdminApproval: {}", groupJoinInfo.pendingAdminApproval());
                    writer.println("description: {}", groupJoinInfo.description());
                    writer.println("isAnnouncementGroup: {}", groupJoinInfo.isAnnouncementGroup());
                }
            }
        } catch (IOException e) {
            throw new IOErrorException("Failed to send message: "
                    + e.getMessage()
                    + " ("
                    + e.getClass().getSimpleName()
                    + ")", e);
        } catch (InactiveGroupLinkException e) {
            throw new UserErrorException("Group link is not valid: " + e.getMessage());
        }
    }
}
