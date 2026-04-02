// src/index.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema
} from "@modelcontextprotocol/sdk/types.js";

// src/google-calendar.service.ts
import { google } from "googleapis";
var GoogleCalendarService = class {
  calendar;
  constructor(auth2) {
    this.calendar = google.calendar({ version: "v3", auth: auth2 });
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
import { z } from "zod";
var GOOGLE_CALENDAR_TOOLS = {
  LIST_EVENTS: {
    name: "list_calendar_events",
    description: "List events from a specific Google Calendar (defaults to 'primary'). Useful for checking your schedule or finding hostel-related events.",
    parameters: z.object({
      calendarId: z.string().default("primary"),
      timeMin: z.string().optional().describe("Start time (ISO 8601)"),
      timeMax: z.string().optional().describe("End time (ISO 8601)"),
      maxResults: z.number().int().min(1).max(2500).default(250),
      q: z.string().optional().describe("Search term")
    })
  },
  CREATE_EVENT: {
    name: "create_calendar_event",
    description: "Create a new event in a Google Calendar. Perfect for scheduling hostel maintenance, student meetings, or reminders.",
    parameters: z.object({
      calendarId: z.string().default("primary"),
      summary: z.string().describe("Title of the event"),
      description: z.string().optional().describe("Detailed description"),
      start: z.object({
        dateTime: z.string().describe("Start time (ISO 8601 formatting, e.g., 2023-01-01T10:00:00Z)"),
        timeZone: z.string().optional()
      }),
      end: z.object({
        dateTime: z.string().describe("End time (ISO 8601 formatting)"),
        timeZone: z.string().optional()
      }),
      attendees: z.array(z.string()).optional().describe("List of emails for attendees")
    })
  },
  UPDATE_EVENT: {
    name: "update_calendar_event",
    description: "Update an existing event in a Google Calendar.",
    parameters: z.object({
      calendarId: z.string().default("primary"),
      eventId: z.string(),
      summary: z.string().optional(),
      description: z.string().optional(),
      start: z.object({
        dateTime: z.string(),
        timeZone: z.string().optional()
      }).optional(),
      end: z.object({
        dateTime: z.string(),
        timeZone: z.string().optional()
      }).optional()
    })
  },
  DELETE_EVENT: {
    name: "delete_calendar_event",
    description: "Delete an event from a calendar.",
    parameters: z.object({
      calendarId: z.string().default("primary"),
      eventId: z.string()
    })
  },
  LIST_CALENDARS: {
    name: "list_calendars",
    description: "List all calendars the current user has access to.",
    parameters: z.object({})
  },
  CHECK_FREE_BUSY: {
    name: "check_calendar_free_busy",
    description: "Check free/busy information for a specific time range across multiple calendars.",
    parameters: z.object({
      timeMin: z.string(),
      timeMax: z.string(),
      items: z.array(z.object({ id: z.string() }))
    })
  }
};

// src/index.ts
import { OAuth2Client } from "google-auth-library";
import * as dotenv from "dotenv";
dotenv.config();
function getAuth() {
  const oauth2Client = new OAuth2Client(
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
var server = new Server(
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
server.setRequestHandler(ListToolsRequestSchema, async () => ({
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
server.setRequestHandler(CallToolRequestSchema, async (request) => {
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
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("\u{1F680} Google Calendar MCP Server started on stdio!");
}
main().catch((error) => {
  console.error("\u274C Fatal error in main():", error);
  process.exit(1);
});
