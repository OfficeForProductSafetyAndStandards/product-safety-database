# Two-Factor Authentication (2FA) Flipper

This document describes the implementation of a Flipper feature for controlling Two-Factor Authentication (2FA) across all environments.

## Overview

A Flipper feature flag for 2FA has been implemented to enable dynamic control of Two-Factor Authentication without requiring code changes or deployments. This allows easier testing and management of the 2FA feature in all environments.

By default, 2FA is enabled for security, but it can be toggled on/off using the Flipper feature via Rails console.

## Implementation Details

The implementation includes:

1. A Flipper feature named `two_factor_authentication` that controls 2FA in all environments
2. A modification to `config/application.rb` to use this Flipper feature
3. A security-first default that enables 2FA if Flipper is unavailable
4. Tests to verify the functionality

## How to Use

### Managing 2FA

You can manage 2FA by using the Rails console in any environment:

```bash
# SSH into the server or local development
# Then open the Rails console
bin/rails console

# Check the current status
Flipper.enabled?(:two_factor_authentication)

# Check the resulting configuration
Rails.configuration.secondary_authentication_enabled
```

### Disabling 2FA

To disable 2FA (for testing purposes only):

```ruby
# In the Rails console
Flipper.disable(:two_factor_authentication)

# Verify the configuration has changed
Rails.configuration.secondary_authentication_enabled  # Should return false
```

### Enabling 2FA

To enable 2FA:

```ruby
# In the Rails console
Flipper.enable(:two_factor_authentication)

# Verify the configuration has changed
Rails.configuration.secondary_authentication_enabled  # Should return true
```

## Important Notes

1. 2FA is **enabled by default** for security reasons
2. If Flipper is not available during application initialization, 2FA defaults to enabled
3. In production, 2FA should generally remain enabled for security
4. Changes to the Flipper feature take effect immediately without requiring restart
5. The feature flag state persists across application restarts

## Related Files

- `config/application.rb` - Contains the logic to use Flipper for 2FA
- `db/migrate/20250314164520_add_two_factor_authentication_flipper.rb` - Creates and enables the Flipper feature
- `spec/features/two_factor_authentication_flipper_spec.rb` - Tests for the feature
- `spec/support/flipper.rb` - Testing helpers for Flipper features

## Testing

For QA testing instructions, see the PR description or consult the QA team.
