# Monastery360

A comprehensive platform for exploring and experiencing Sikkim's monasteries digitally.

## 🌟 Features

### For Visitors

- **Interactive Monastery Explorer**: Browse detailed information about various monasteries
- **Event Calendar**: View and book upcoming monastery events and ceremonies
- **Digital Gallery**: High-quality images and virtual tours of monasteries
- **Digital Archives**: Access historical documents and religious texts
- **Interactive Map**: Locate monasteries with precise coordinates
- **Booking System**: Reserve spots for events and ceremonies

### For Administrators

- **Content Management**: Add and update monastery information (done via direct API requests)  
- **Event Management**: Schedule and manage monastery events (done via direct API requests)  
- **Archive Management**: Upload and organize digital archives (done via direct API requests)  
- **Image Gallery Control**: Curate and manage monastery images (done via direct API requests)  
- **Booking Overview**: Track and manage event bookings (done via direct API requests)


## 🚀 Live Demo

- Frontend: [Live Site](https://monastery360-theta.vercel.app)
- Backend API: [API Endpoint](https://monastery360-backend.onrender.com)

## 🛠️ Tech Stack

### Frontend

- React.js
- Redux for state management
- Tailwind CSS for styling
- Axios for API calls

### Backend

- Node.js
- Express.js
- MongoDB
- Cloudinary for image storage

## 📋 Prerequisites

- Node.js (v14 or higher)
- MongoDB
- Cloudinary account
- npm or yarn

## ⚙️ Setup and Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ManavPratapSingh-off/Monastery360.git
   cd Monastery360
   ```

2. **Setup Environment Variables**

   Create `.env` file in server directory:

   ```env
   DB_URL=mongodb+srv://manav24bcs10126_db_user:Mannu%40scaler2028@monastery360.ucn8wkk.mongodb.net/?retryWrites=true&w=majority&appName=Monastery360
   CLOUDINARY_URL=cloudinary://231494826523796:Z1EWiqOiNb3bw5-A8bjhJqn409g@diupsjs3r
   CLIENT_URL=https://monastery360-theta.vercel.app
   ```

3. **Install Dependencies**

   ```bash
   # Install server dependencies
   cd server
   npm install

   # Install client dependencies
   cd ../client
   npm install
   ```

4. **Run the Application**

   ```bash
   # Start server (from server directory)
   npm start

   # Start client (from client directory)
   npm run dev
   ```

## 📱 API Endpoints

### Monasteries

- `GET /api/monasteries` - Get all monasteries
- `POST /api/monasteries` - Add new monastery
- `GET /api/monasteries/:id` - Get specific monastery

### Events

- `GET /api/events` - Get all events
- `POST /api/events` - Create new event
- `GET /api/events/:id` - Get specific event

### Images

- `GET /api/images` - Get all images
- `POST /api/images` - Upload new image

### Archives

- `GET /api/archives` - Get all archives
- `POST /api/archives` - Upload new archive
- `GET /api/archives/search` - Search archives
