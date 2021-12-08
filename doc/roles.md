# Roles

Users of the Product Safety Database will normally not require any specific roles to be defined in order to use the service. Exceptionally they may have one or more roles which allow them to perform priveleged actions not ordinarily available to other users.

Roles may be applied to users individually, or to a whole team. When a role is applied to a team, it is inferred that all users within that team are assigned that role.

Accordingly, roles are defined in the `Role` model which may be associated with the `User` and/or `Team` models. The role is defined by the `name` attribute of the `Role` model.

The available role names and their meanings are described below:

|Role name|Meaning|
|---------|-------|
|`team_admin`|One or more members of each team should ordinarily have this role, which allows them to send and re-send invitations to new users to create an account on the Product Safety Database as a member of their team, or to remove users from their team.|
|`opss`|Normally set at the team level for OPSS teams and alters certain presentation and navigation elements accordingly.|
|`psd_admin`|Allows the user to export data from case, business and product listings in spreadsheet format. Restricted to specific OPSS teams.|
|`notifying_country_editor`|Allows the user to edit the notifying country of any case on the Product Safety Database.  Restricted to specific OPSS teams.|
|`risk_level_validator`|Allows the user to mark the risk level of any case on the Product Safety Database as 'validated'. Restricted to specific OPSS teams.|
|`email_alert_sender`|Allows the user to send an e-mail product safety alert to all users of the Product Safety Database. Restricted to specific OPSS teams.|
|`restricted_case_viewer`|Allows the user to view all data on the Product Safety Database, including restricted cases, even when their team is not specifically added to the case. Highly restricted to specific OPSS teams for auditing purposes.|
