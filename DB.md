# Unified Chat Database Schema

This document describes the unified database architecture for the messenger, supporting Direct Chats, Groups, and Channels in a single standardized schema.

## Enums

### `room_type`
Defines the nature of the chat room.
- `direct`: One-on-one private chat.
- `group`: Multi-user group chat.
- `channel`: One-to-many broadcast channel.

---

## Table `profiles`
Stores user profile information, linked to Supabase Auth.

### Columns
| Name | Type | Constraints | Description |
|------|------|-------------|-------------|
| `id` | `uuid` | Primary Key | Linked to `auth.users.id` |
| `username` | `text` | Unique, Not Null | Case-insensitive via index |
| `nickname` | `text` | Nullable | User's display name |
| `avatar_url` | `text` | Nullable | URL to profile picture |
| `is_online` | `boolean` | Default: `false` | Presence status |
| `updated_at` | `timestamptz` | Default: `now()` | Last update timestamp |

---

## Table `rooms`
The central table for all types of conversations.

### Columns
| Name | Type | Constraints | Description |
|------|------|-------------|-------------|
| `id` | `uuid` | Primary Key | Unique room identifier |
| `type` | `room_type` | Not Null | `direct`, `group`, or `channel` |
| `name` | `text` | Nullable | Group or Channel name |
| `description` | `text` | Nullable | Group or Channel info |
| `avatar_url` | `text` | Nullable | Room icon |
| `created_at` | `timestamptz` | Default: `now()` | Room creation time |
| `last_message_at` | `timestamptz` | Default: `now()` | Used for sorting chat list |
| `created_by` | `uuid` | FK (profiles) | Owner/Creator of the room |

---

## Table `room_participants`
Links users to rooms they have joined.

### Columns
| Name | Type | Constraints | Description |
|------|------|-------------|-------------|
| `room_id` | `uuid` | Composite PK, FK | Link to `rooms` |
| `profile_id` | `uuid` | Composite PK, FK | Link to `profiles` |
| `role` | `text` | Default: `'member'` | `owner`, `admin`, or `member` |
| `joined_at` | `timestamptz` | Default: `now()` | When user joined |

---

## Table `messages`
Single source of truth for all messages in the application.

### Columns
| Name | Type | Constraints | Description |
|------|------|-------------|-------------|
| `id` | `uuid` | Primary Key | Message identifier |
| `room_id` | `uuid` | FK (rooms) | Where the message was sent |
| `profile_id` | `uuid` | FK (profiles) | Who sent the message |
| `content` | `text` | Not Null | Message body |
| `created_at` | `timestamptz` | Default: `now()` | Sending time |
| `is_edited` | `boolean` | Default: `false` | Edit flag |
| `reply_to_id` | `uuid` | FK (messages) | Reference for replies |

---

## Realtime Configuration
Realtime is enabled for the following tables via `supabase_realtime` publication:
- `profiles`
- `rooms`
- `room_participants`
- `messages`
