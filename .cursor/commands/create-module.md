# create-module
Create a new module in /src/modules/<name> with the following structure:

/controllers/<name>.controller.ts
/services/<name>.service.ts
/routes/<name>.routes.ts
/models/<name>.model.ts
/utils/<name>.utils.ts

Populate each file with a clean boilerplate following project rules.
Do not add any business logic. Only skeletons.
Register the new route automatically in the root router if exists.

This command will be available in chat with /create-module
