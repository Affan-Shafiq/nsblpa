# Admin Features Documentation

## Overview
The NSBLPA Players App now includes role-based access control with admin functionality for managing endorsements and player requests.

## Role System

### Player Role (Default)
- Default role assigned to new users
- Can view available endorsements
- Can request endorsements
- Can view their own endorsement requests and status

### Admin Role
- Full access to all app features
- Can create new endorsement opportunities
- Can approve/reject player endorsement requests
- Can view all endorsements and their statuses
- Access to admin panel

## Admin Features

### 1. Admin Panel (`/admin`)
The admin panel provides three main tabs:

#### Pending Requests Tab
- View all endorsement requests with "pending" status
- See player details for each request
- Approve or reject requests
- Requests show brand name, category, value, and requirements

#### All Endorsements Tab
- View all endorsements in the system
- See status of each endorsement (available, active, pending, rejected, expired)
- Monitor endorsement activity

#### Add New Tab
- Create new endorsement opportunities
- Set brand name, category, description, value, duration
- Add requirements for the endorsement
- New endorsements are created with "available" status

### 2. Dashboard Integration
- Admin users see an "Admin Actions" section on their dashboard
- Quick access to the admin panel
- Only visible to users with admin role

## How to Set Up Admin Access

### Method 1: Development Tools
1. Navigate to the "Dev" tab in the bottom navigation
2. Click "Create Admin User" 
3. This will update the current user's role to "admin"

### Method 2: Direct Database Update
Update the player document in Firestore:
```json
{
  "role": "admin"
}
```

## Endorsement Workflow

### For Players:
1. View available endorsements in the "Available Opportunities" tab
2. Click "Apply Now" on desired endorsement
3. Confirm application
4. Request is created with "pending" status
5. Applied endorsement disappears from available list
6. Monitor status in "My Endorsements" tab

**Note**: Once a player applies for an endorsement, it will no longer appear in their "Available Opportunities" tab to prevent duplicate applications.

### For Admins:
1. View pending requests in admin panel
2. Review player details and endorsement information
3. Approve or reject the request
4. Approved requests become "active"
5. Rejected requests are permanently deleted from the database

## Database Schema Updates

### Players Collection
Added field:
- `role`: String - "player" (default) or "admin"

### Endorsements Collection
Fields:
- `userId`: String - Firebase Auth UID of requesting player (empty for available endorsements)
- `status`: String - "available", "pending", "active", "expired"
- `brandName`: String - Name of the brand
- `category`: String - Category of endorsement
- `description`: String - Description of the endorsement
- `value`: Number - Monetary value of the endorsement
- `duration`: String - Duration of the endorsement
- `requirements`: Array - List of requirements
- `createdAt`: Timestamp - When the endorsement was created
- `updatedAt`: Timestamp - When the endorsement was last updated

**Note**: Rejected endorsements are permanently deleted from the database rather than marked as "rejected".

## Security Considerations

- Admin functions are protected by role checks
- Only users with admin role can access admin panel
- All admin operations verify admin status before execution
- Player requests are tied to their Firebase Auth UID

## Testing

1. Create a regular user account
2. Use the development tools to create sample endorsements
3. Apply for endorsements as a regular user
4. Use development tools to make a user admin
5. Access admin panel to approve/reject requests
6. Verify status changes in both admin and player views

## Future Enhancements

- Email notifications for status changes
- Bulk approval/rejection of requests
- Endorsement analytics and reporting
- Advanced filtering and search in admin panel
- Endorsement templates for quick creation 