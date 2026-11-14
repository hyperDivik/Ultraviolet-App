# Connectors

This plugin works standalone; it only needs a shell and the repository.
Like the knowledge-work-plugins, skills refer to optional tools by category:

| Category       | Placeholder        | Examples                       | Used for                                                            |
| -------------- | ------------------ | ------------------------------ | ------------------------------------------------------------------- |
| Source control | `~~source control` | GitHub                         | Reading PRs and upstream release notes before updating dependencies |
| Hosting        | `~~hosting`        | Railway, Koyeb, Heroku, Fly.io | Reading deploy logs and env vars when a deploy misbehaves           |

No `.mcp.json` ships by default. Add one at the plugin root if you want those connections.
