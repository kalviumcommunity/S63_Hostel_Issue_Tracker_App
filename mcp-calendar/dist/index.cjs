"use strict";
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// src/index.ts
var import_server = require("@modelcontextprotocol/sdk/server/index.js");
var import_stdio = require("@modelcontextprotocol/sdk/server/stdio.js");
var import_types = require("@modelcontextprotocol/sdk/types.js");

// src/google-calendar.service.ts
var import_googleapis = require("googleapis");
var GoogleCalendarService = class {
  calendar;
  constructor(auth2) {
    this.calendar = import_googleapis.google.calendar({ version: "v3", auth: auth2 });
  }
  /**
   * List events from a given calendar.
   * @param params Parameters for the events.list call: calendarId, timeMin, timeMax, etc.
   */
  async listEvents(params) {
    const response = await this.calendar.events.list(params);
    return response.data;
  }
  /**
   * Create a new event on a calendar.
   */
  async createEvent(calendarId, resource) {
    const response = await this.calendar.events.insert({
      calendarId,
      requestBody: resource
    });
    return response.data;
  }
  /**
   * Update an existing event.
   */
  async updateEvent(calendarId, eventId, resource) {
    const response = await this.calendar.events.update({
      calendarId,
      eventId,
      requestBody: resource
    });
    return response.data;
  }
  /**
   * Delete an event.
   */
  async deleteEvent(calendarId, eventId) {
    await this.calendar.events.delete({
      calendarId,
      eventId
    });
    return { success: true, message: `Event ${eventId} deleted successfully.` };
  }
  /**
   * List all calendars the user has access to.
   */
  async listCalendars() {
    const response = await this.calendar.calendarList.list();
    return response.data;
  }
  /**
   * Get free/busy information for a set of calendars.
   */
  async checkFreeBusy(timeMin, timeMax, items) {
    const response = await this.calendar.freebusy.query({
      requestBody: {
        timeMin,
        timeMax,
        items
      }
    });
    return response.data;
  }
};

// src/tools.ts
var import_zod = require("zod");
var GOOGLE_CALENDAR_TOOLS = {
  LIST_EVENTS: {
    name: "list_calendar_events",
    description: "List events from a specific Google Calendar (defaults to 'primary'). Useful for checking your schedule or finding hostel-related events.",
    parameters: import_zod.z.object({
      calendarId: import_zod.z.string().default("primary"),
      timeMin: import_zod.z.string().optional().describe("Start time (ISO 8601)"),
      timeMax: import_zod.z.string().optional().describe("End time (ISO 8601)"),
      maxResults: import_zod.z.number().int().min(1).max(2500).default(250),
      q: import_zod.z.string().optional().describe("Search term")
    })
  },
  CREATE_EVENT: {
    name: "create_calendar_event",
    description: "Create a new event in a Google Calendar. Perfect for scheduling hostel maintenance, student meetings, or reminders.",
    parameters: import_zod.z.object({
      calendarId: import_zod.z.string().default("primary"),
      summary: import_zod.z.string().describe("Title of the event"),
      description: import_zod.z.string().optional().describe("Detailed description"),
      start: import_zod.z.object({
        dateTime: import_zod.z.string().describe("Start time (ISO 8601 formatting, e.g., 2023-01-01T10:00:00Z)"),
        timeZone: import_zod.z.string().optional()
      }),
      end: import_zod.z.object({
        dateTime: import_zod.z.string().describe("End time (ISO 8601 formatting)"),
        timeZone: import_zod.z.string().optional()
      }),
      attendees: import_zod.z.array(import_zod.z.string()).optional().describe("List of emails for attendees")
    })
  },
  UPDATE_EVENT: {
    name: "update_calendar_event",
    description: "Update an existing event in a Google Calendar.",
    parameters: import_zod.z.object({
      calendarId: import_zod.z.string().default("primary"),
      eventId: import_zod.z.string(),
      summary: import_zod.z.string().optional(),
      description: import_zod.z.string().optional(),
      start: import_zod.z.object({
        dateTime: import_zod.z.string(),
        timeZone: import_zod.z.string().optional()
      }).optional(),
      end: import_zod.z.object({
        dateTime: import_zod.z.string(),
        timeZone: import_zod.z.string().optional()
      }).optional()
    })
  },
  DELETE_EVENT: {
    name: "delete_calendar_event",
    description: "Delete an event from a calendar.",
    parameters: import_zod.z.object({
      calendarId: import_zod.z.string().default("primary"),
      eventId: import_zod.z.string()
    })
  },
  LIST_CALENDARS: {
    name: "list_calendars",
    description: "List all calendars the current user has access to.",
    parameters: import_zod.z.object({})
  },
  CHECK_FREE_BUSY: {
    name: "check_calendar_free_busy",
    description: "Check free/busy information for a specific time range across multiple calendars.",
    parameters: import_zod.z.object({
      timeMin: import_zod.z.string(),
      timeMax: import_zod.z.string(),
      items: import_zod.z.array(import_zod.z.object({ id: import_zod.z.string() }))
    })
  }
};

// src/index.ts
var import_google_auth_library = require("google-auth-library");
var dotenv = __toESM(require("dotenv"), 1);
dotenv.config();
function getAuth() {
  const oauth2Client = new import_google_auth_library.OAuth2Client(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URL || "http://localhost:3000"
  );
  if (process.env.GOOGLE_REFRESH_TOKEN) {
    oauth2Client.setCredentials({
      refresh_token: process.env.GOOGLE_REFRESH_TOKEN
    });
  }
  return oauth2Client;
}
var auth = getAuth();
var calendarService = new GoogleCalendarService(auth);
var server = new import_server.Server(
  {
    name: "mcp-tool-google-calendar",
    version: "1.0.0"
  },
  {
    capabilities: {
      tools: {}
    }
  }
);
server.setRequestHandler(import_types.ListToolsRequestSchema, async () => ({
  tools: Object.values(GOOGLE_CALENDAR_TOOLS).map((tool) => ({
    name: tool.name,
    description: tool.description,
    inputSchema: {
      type: "object",
      properties: {},
      // Simplified: In a real app, use zod-to-json-schema
      required: []
    }
  }))
}));
server.setRequestHandler(import_types.CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  try {
    switch (name) {
      case GOOGLE_CALENDAR_TOOLS.LIST_EVENTS.name: {
        const validated = GOOGLE_CALENDAR_TOOLS.LIST_EVENTS.parameters.parse(args);
        const result = await calendarService.listEvents(validated);
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case GOOGLE_CALENDAR_TOOLS.CREATE_EVENT.name: {
        const validated = GOOGLE_CALENDAR_TOOLS.CREATE_EVENT.parameters.parse(args);
        const { calendarId, ...resource } = validated;
        const result = await calendarService.createEvent(calendarId, resource);
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case GOOGLE_CALENDAR_TOOLS.LIST_CALENDARS.name: {
        const result = await calendarService.listCalendars();
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case GOOGLE_CALENDAR_TOOLS.DELETE_EVENT.name: {
        const validated = GOOGLE_CALENDAR_TOOLS.DELETE_EVENT.parameters.parse(args);
        const result = await calendarService.deleteEvent(validated.calendarId, validated.eventId);
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      default:
        throw new Error(`Tool ${name} not found.`);
    }
  } catch (error) {
    return {
      content: [{ type: "text", text: `Error: ${error.message}` }],
      isError: true
    };
  }
});
async function main() {
  const transport = new import_stdio.StdioServerTransport();
  await server.connect(transport);
  console.error("\u{1F680} Google Calendar MCP Server started on stdio!");
}
main().catch((error) => {
  console.error("\u274C Fatal error in main():", error);
  process.exit(1);
});
