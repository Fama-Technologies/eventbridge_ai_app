# Vendor Portfolio Redesign

## Summary

Replace the existing 3 portfolio screen files with a single, clean "folder grid" portfolio experience. Two screens: a main grid view and a project detail gallery.

## What Changes

- **Delete:** `vendor_portfolio_screen.dart`, `vendor_portfolio_improved.dart`, `vendor_portfolio_redesigned.dart`
- **Create:** `vendor_portfolio_screen.dart` (main grid), `vendor_portfolio_detail_screen.dart` (project gallery)
- **Keep:** `widgets/portfolio_dialogs.dart` (reused as-is)
- **Update:** `app_router.dart` to point `/vendor-portfolio` at the new screen and add `/vendor-portfolio-detail` route

## Screen 1: Portfolio Main (Grid)

### Header
- Solid `AppColors.primary01` background, white text
- Title: "My Portfolio" left-aligned, Outfit 20px w700
- Right: project count in white pill badge
- Left: back arrow (white)

### Filter Chips
- Horizontal scrollable row below header, 12px vertical padding
- Chips: All, Weddings, Corporate, Parties, Other
- Active: `AppColors.primary01` fill, white text
- Inactive: white fill, `AppColors.textSecondary` text, `AppColors.border` outline
- Radius: `AppRadius.chip` (20)

### Project Grid
- 2-column `GridView`, crossAxisSpacing 12, mainAxisSpacing 12, padding 16
- childAspectRatio: 0.85
- Card: `ClipRRect` with `AppRadius.card` (14)
  - Hero thumbnail fills card (`BoxFit.cover`)
  - Bottom gradient scrim: transparent -> black 70%, covers bottom 40%
  - Project name: white, Outfit 14px w600, max 1 line ellipsis
  - Tags: tiny pills with semi-transparent white bg, white text 10px
  - Top-right: image count badge (primary01 circle, white text)
  - Subtle BoxShadow

### FAB
- Bottom-right, 16px from edges, 90px from bottom
- `AppColors.primary01` circle, white add icon
- Opens existing `PortfolioActionDialog`

### Empty State
- Centered folder icon, title, subtitle, primary "Add Project" button

## Screen 2: Project Detail (Gallery)

### Header
- Solid `AppColors.primary01`, white title = project name
- Back arrow left, overflow menu right (edit, delete project)

### Info Bar
- White surface below header
- Tags as colored chips, description (expandable), image count

### Image Grid
- 3-column grid of square thumbnails, 4px spacing
- Tap: full-screen image viewer with swipe
- Long-press: select mode for multi-delete

### Add Images FAB
- Same style, opens `ManageProjectImagesDialog`

## Data Model

Uses existing `VendorProject` from `match_vendor.dart` — no model changes needed.

## Design Tokens

All from existing `app_theme.dart` / `app_colors.dart`:
- `AppColors.primary01`, `AppColors.textSecondary`, `AppColors.border`, `AppColors.cardBg`
- `AppRadius.card` (14), `AppRadius.chip` (20)
- `AppSpacing.lg` (16), `AppSpacing.md` (12)
