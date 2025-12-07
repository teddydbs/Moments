# 🎉 Moments - iOS Event & Wishlist Management App

> Never miss a birthday, wedding, or special moment again!

**Moments** is a beautiful iOS app built with SwiftUI that helps you manage events, track birthdays, create wishlists, and organize celebrations with your loved ones.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green)
![SwiftData](https://img.shields.io/badge/SwiftData-Latest-purple)

## ✨ Features

### 🏠 Home Dashboard
- **Upcoming birthdays** carousel with countdown
- **Events overview** with quick access
- Personalized greeting with profile picture
- Search functionality across all data

### 🎂 Birthday Management
- Track friends & family birthdays
- Automatic age calculation
- Days until next birthday countdown
- View contact wishlists
- "Today", "This Week", "Upcoming" sections

### 📅 Event Organization
- Create your own events (birthdays, weddings, parties, etc.)
- Invite management with approval workflow
- Guest list with RSVP tracking
- Event-specific wishlists
- **Interactive map** with automatic address geocoding
- Location and time management

### 🎁 Smart Wishlists
- Create wishlists for your events
- View wishlists of your contacts
- **Auto-fill product info** from URLs (Amazon, Fnac, etc.)
- Product images, titles, and prices
- Priority levels and categories
- Status tracking (wanted, reserved, purchased)

### 🪄 Auto-Fill Magic
- Paste a product URL
- Click "Auto-fill" button
- Get product name, image, and price automatically
- Uses Apple's LinkPresentation framework
- Works with most e-commerce sites

### 👥 Invitation Management
- Send invitations to events
- Track RSVP status
- Approve/reject guest requests
- +1 management
- Integration with contacts

### 👤 User Profile
- Personal information management
- Profile picture
- Account settings
- Logout functionality

## 🏗️ Architecture

### Tech Stack
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Persistence:** SwiftData (local storage)
- **Backend:** Supabase (configured, ready to use)
- **Minimum iOS:** 17.0+

### Project Structure
```
Moments/
├── Models/              # SwiftData models
│   ├── AppUser.swift    # User profile
│   ├── Contact.swift    # Friends & family
│   ├── MyEvent.swift    # User's events
│   ├── WishlistItem.swift
│   └── Invitation.swift
├── Views/               # SwiftUI views
│   ├── HomeView.swift   # Main dashboard
│   ├── Auth/            # Authentication
│   ├── BirthdaysView.swift
│   ├── EventsView.swift
│   └── MyWishlistView.swift
├── Services/            # Business logic
│   ├── AuthManager.swift
│   └── ProductMetadataFetcher.swift
└── Helpers/
    ├── Theme.swift      # Design system
    └── SampleData.swift # Test data
```

## 🎨 Design System

### Colors
- **Primary Purple:** `#9D4EDD`
- **Primary Pink:** `#FF006E`
- **Gradient:** Purple → Pink diagonal

### Components
- Custom button styles
- Gradient icons
- Card-based layouts
- Modern glassmorphism effects

## 🚀 Getting Started

### Prerequisites
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- iOS 17.0+ device or simulator

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/Moments.git
cd Moments
```

2. **Open in Xcode**
```bash
open Moments.xcodeproj
```

3. **Build and Run**
- Select your target device/simulator
- Press `Cmd+R` or click the Play button

### First Launch
- The app will create sample data automatically
- Login with any credentials (mock authentication)
- Explore the pre-populated events and contacts

## 📱 Usage

### Adding a Product to Wishlist

1. Go to your event or contact's wishlist
2. Click "Add Gift"
3. Paste a product URL (Amazon, Fnac, etc.)
4. Click ✨ "Auto-fill"
5. Review and save!

**Supported sites:**
- Amazon (.fr, .com, .de, etc.)
- Fnac
- Boulanger
- Darty
- And most e-commerce websites!

### Creating an Event

1. Go to Events tab
2. Click "+" button
3. Fill in event details:
   - Type (Birthday, Wedding, Party, etc.)
   - Title, date, time
   - Location
   - Max guests
4. Add your wishlist
5. Invite guests

### Managing Invitations

1. Open your event
2. Click "Manage Invitations"
3. Add guests (from contacts or manually)
4. Approve/reject RSVP requests
5. Track attendance

## 🔧 Configuration

### Supabase Setup (Optional)
The app is ready for Supabase integration:

1. Create a Supabase project
2. Update `SupabaseConfig.swift`:
```swift
static let supabaseURL = "YOUR_SUPABASE_URL"
static let supabaseAnonKey = "YOUR_ANON_KEY"
```

### Authentication
Currently uses mock authentication (AuthManager).
To enable real auth:
- Uncomment Supabase auth code
- Connect to your backend

## 📚 Documentation

- **[NEW_ARCHITECTURE.md](NEW_ARCHITECTURE.md)** - Architecture details
- **[AUTO_FILL_GUIDE.md](AUTO_FILL_GUIDE.md)** - Auto-fill feature guide
- **[MAP_FEATURE_GUIDE.md](MAP_FEATURE_GUIDE.md)** - Interactive map feature guide
- **[AUTH_TEST_GUIDE.md](AUTH_TEST_GUIDE.md)** - Authentication testing

## 🧪 Testing

### Sample Data
The app automatically creates test data on first launch:
- 5 contacts with upcoming birthdays
- 4 events (wedding, birthday, baby shower, graduation)
- Multiple wishlist items

### Reset Data
To reset all data:
1. Delete the app from simulator/device
2. Reinstall

## 🎯 Roadmap

### Current Features ✅
- [x] Home dashboard with upcoming events
- [x] Birthday tracking
- [x] Event management with interactive maps
- [x] Wishlist creation
- [x] Auto-fill from product URLs
- [x] Invitation system
- [x] Mock authentication

### Upcoming Features 🚧
- [ ] Real Supabase authentication
- [ ] Cloud sync across devices
- [ ] Push notifications for birthdays
- [ ] Sharing wishlists via link
- [ ] Gift contribution/pooling
- [ ] Calendar integration
- [ ] Photo galleries for events
- [ ] Export to PDF

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Teddy Dubois**

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI
- Icons by SF Symbols
- Auto-fill powered by LinkPresentation
- Design inspired by modern iOS apps

## 📞 Support

If you have any questions or issues, please open an issue on GitHub.

---

**Made with 💜 and SwiftUI**

*Remember: Never miss a moment that matters!* 🎉
