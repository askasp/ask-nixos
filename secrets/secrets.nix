let
  # Define your SSH public keys here
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7HUw9xkUMR+dFKM9kGZau8ql4T06J9f2x34UHNnB+M user@example.com";
  
  # Define your host keys here (these will be generated during installation)
  # You'll need to update these with your actual host keys after your first boot
  # Run `ssh-keyscan -t ed25519 localhost` on your host to get these keys after installation
  cirrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsCb3MMLaI1g+nntDLwnv26w3i98ESeGDsdRO2OTgZi cirrus7numbus@stadler.no";
in
{
  # Define your secrets and who can access them
  # Format: "secrets/name.age" = [ publickeys... ];
  
  # Anthropic API key - can be decrypted by the Cirrus machine
  "secrets/anthropic-api-key.age".publicKeys = [ cirrus ];

  "secrets/openrouter-api-key.age".publicKeys = [ cirrus ];
  
  # Amino API environment variables
  "secrets/amino-api-keys.age".publicKeys = [ cirrus ];
  
  # CQRS Server environment variables
  "secrets/cqrs-server-keys.age".publicKeys = [ cirrus ];
  
  # Example secrets (uncomment and modify as needed)
  # "secrets/example.age" = [ user1 cirrus ];
  # "secrets/credentials.age" = [ user1 cirrus ];
} 