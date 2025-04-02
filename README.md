# Comics Writer

A powerful iOS app for creating and managing Western-style comic book scripts.

## Features

- **Series Management**: Organize your comics into series with custom cover images
- **Issue Organization**: Create issues within series with their own cover images
- **Script Editor**: Professional script formatting with:
  - Visual page and panel organization
  - Interactive outline navigation
  - Character dialogue management
  - Automatic formatting

## App Structure

The app follows a three-level navigation hierarchy:

1. **Series View**: Shows all available comic series with a grid of cover images
2. **Issues View**: Shows all issues within a selected series
3. **Script Editor**: The heart of the app where you write your comic scripts

### Script Editor Features

The script editor provides a professional workflow for comic script writing:

- Left sidebar with an interactive outline of pages and panels
- Main editing area showing the current page and its panels
- Support for adding character dialogue
- Automatic formatting according to comic industry standards

## Technical Details

- Built with SwiftUI and SwiftData for persistent storage
- Clean architecture with separation of models, views, and components
- Support for image selection and storage
- Hierarchical data model (Series → Issues → Pages → Panels → Characters)

## Future Enhancements

- Export to PDF and other formats
- Support for different script templates
- Collaboration features
- Cloud sync across devices
- More visual customization options
