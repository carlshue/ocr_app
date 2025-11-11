# 🧾 Flutter Ticket OCR App (User Side)

This Flutter app allows users to capture or select ticket images, preprocess them, and send them to a remote server for OCR (Optical Character Recognition). The app then lets users view, edit, and save the extracted data — making it easy to manage shared expenses like restaurant bills or event tickets.

## ✨ Features

📸 Capture or select images from the gallery or camera.

⚙️ Preprocess images (grayscale, binarization) to improve OCR accuracy.

☁️ Upload to OCR server and receive structured data (JSON).

🧠 Edit extracted information manually to fix OCR errors or add details.

💾 Save tickets locally for future access — even offline.

👥 Split bills easily: assign items or amounts to friends and calculate who owes what.

📊 View all tickets in a clean local history with totals and notes.

## 🔄 User Flow

```mermaid
flowchart LR
    A["Flutter App / User"] --> B["Select or capture ticket image"]
    B --> C["Preprocess image (grayscale, binarization, skewing...)"]
    C --> D["Upload image to OCR Server (Railway)"]

    E["Receive structured data (JSON) from server"] --> F["User may edit or correct OCR results"]
    F --> G["When user assigns costs to friends calculate totals"]
    G --> H["Save ticket and calculations locally"]

    click D "https://github.com/carlshue/ocr_ticketing" "Go to GitHub repo"
```
## ⚙️ How It Works

## ⚙️ How It Works

| Step | Screenshot | Description |
|------|------------|-------------|
| 1️⃣ Select Image | ![Select Image](docs/images/1select_ticket_example2.png) | Users can choose or capture an image of a ticket or bill using the `image_picker` plugin. |
| 2️⃣ View Ticket Info | ![View Ticket Info](docs/images/3_view_ticket_info.png) | After OCR, users see the extracted ticket information in a clean table view. |
| 3️⃣ Edit & Modify Ticket | ![Modify Ticket Info](docs/images/4_modify_ticket_info.png) | Users can correct misread items, add missing prices, or update other ticket details. |
| 4️⃣ Choose People | ![Choose People](docs/images/5_choose_names_of_people_who_consumed_somthing.png) | Assign each item on the ticket to the friends who consumed it. |
| 5️⃣ Choose Payer | ![Choose Payer](docs/images/6_choose_payer_of_the_bill.png) | Select which friend paid the bill or split payment. |
| 6️⃣ Assign Items | ![Assign Items](docs/images/7_choose_which_items_every_person_consumed.png) | Determine who consumed which items to calculate individual totals. |
| 7️⃣ Calculation Results | ![Calculation Results](docs/images/8_calculations_results.png) | The app automatically calculates totals for each person based on consumption. |
| 8️⃣ Save Locally | ![Save Locally](docs/images/2select_ticket_example2.png) | All tickets (with edits and calculations) are stored securely on the device. Users can reopen them anytime, even offline. |




## 📦 Dependencies
Package	Purpose
image_picker	Capture or pick images
http	Upload images & receive OCR JSON
image	Image preprocessing
path_provider	Manage local storage paths
dart:io, dart:convert	File I/O & JSON parsing
sqflite / hive	Local ticket storage
provider / riverpod	State management
flutter_math / intl	Bill calculations & formatting

## 🗂️ Local Data Storage
Tickets are stored locally with:
Processed OCR text and metadata
Editable fields (title, date, location, etc.)
Friend-based bill splits
Notes or tags


📝 Notes
* ![server side](https://github.com/carlshue/ocr_app/tree/main)


Preprocessing helps improve OCR accuracy by removing noise and adjusting contrast.

All data (tickets, notes, friends, calculations) remain local and private to the device.

You can expand the app to sync with the cloud or share tickets between users in future versions.
