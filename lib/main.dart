import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class Note {
  final String id;
  String title;
  String content;
  DateTime date;
  String category;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.category = 'General',
    this.isPinned = false,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF2D2D2D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D2D),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: HomeScreen(), // <-- THIS WAS MISSING
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'General',
    'Personal',
    'Work',
    'Ideas'
  ];

  void _addOrUpdateNote(Note note) {
    setState(() {
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        notes[index] = note;
      } else {
        notes.add(note);
      }
    });
  }

  void _deleteNote(String id) {
    setState(() {
      notes.removeWhere((note) => note.id == id);
    });
  }

  List<Note> get filteredNotes {
    return notes.where((note) {
      final matchesSearch =
          note.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              note.content.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' || note.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _togglePin(Note note) {
    setState(() {
      note.isPinned = !note.isPinned;
    });
  }

  void _showNoteEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    if (result != null) {
      _addOrUpdateNote(result);
    }
  }

  Widget _buildCategoryFilter() {
    return PopupMenuButton<String>(
      onSelected: (value) => setState(() => selectedCategory = value),
      itemBuilder: (context) => categories.map((category) {
        return PopupMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      icon: Icon(Icons.filter_list),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Personal':
        return Colors.blue[800]!;
      case 'Work':
        return Colors.green[800]!;
      case 'Ideas':
        return Colors.purple[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildNoteItem(Note note) {
    return Dismissible(
      key: Key(note.id),
      background: Container(color: Colors.red),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNote(note.id),
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        color: Color(0xFF2D2D2D),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title:
              Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(note.category),
                    backgroundColor: _getCategoryColor(note.category),
                  ),
                  Spacer(),
                  Text(
                    '${note.date.day}/${note.date.month}/${note.date.year}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteNote(note.id),
          ),
          onTap: () => _showNoteEditor(note: note),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredNotes.length,
      itemBuilder: (ctx, index) => _buildNoteItem(filteredNotes[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: NotesSearch(notes),
            ),
          ),
          _buildCategoryFilter(),
        ],
      ),
      body: _buildNoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  NoteEditorScreen({this.note});

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedCategory = 'General';
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedCategory = widget.note?.category ?? 'General';
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty) {
      // Simple validation: title must not be empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    final newNote = Note(
      id: widget.note?.id ?? DateTime.now().toString(),
      title: _titleController.text,
      content: _contentController.text,
      date: DateTime.now(),
      category: _selectedCategory,
      isPinned: widget.note?.isPinned ?? false,
    );
    Navigator.pop(context, newNote);
  }

  void _toggleBold() {
    setState(() => _isBold = !_isBold);
  }

  void _toggleItalic() {
    setState(() => _isItalic = !_isItalic);
  }

  void _toggleUnderline() {
    setState(() => _isUnderline = !_isUnderline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: 'Note title',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Column(
        children: [
          _buildFormattingToolbar(),
          _buildCategorySelector(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: _isUnderline
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                decoration: InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      height: 50,
      color: Color(0xFF2D2D2D),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.format_bold),
            color: _isBold ? Colors.amber : Colors.grey,
            onPressed: _toggleBold,
          ),
          IconButton(
            icon: Icon(Icons.format_italic),
            color: _isItalic ? Colors.amber : Colors.grey,
            onPressed: _toggleItalic,
          ),
          IconButton(
            icon: Icon(Icons.format_underline),
            color: _isUnderline ? Colors.amber : Colors.grey,
            onPressed: _toggleUnderline,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['General', 'Personal', 'Work', 'Ideas'];
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        dropdownColor: Color(0xFF2D2D2D),
        items: categories.map((cat) {
          return DropdownMenuItem(
            value: cat,
            child: Text(cat, style: TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedCategory = val);
        },
      ),
    );
  }
}

class NotesSearch extends SearchDelegate<Note?> {
  final List<Note> notes;

  NotesSearch(this.notes);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = notes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.content.toLowerCase().contains(query.toLowerCase()));
    return ListView(
      children: results
          .map((note) => ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => close(context, note),
              ))
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = notes.where((note) =>
        note.title.toLowerCase().contains(query.toLowerCase()) ||
        note.content.toLowerCase().contains(query.toLowerCase()));
    return ListView(
      children: suggestions
          .map((note) => ListTile(
                title: Text(note.title),
                onTap: () {
                  query = note.title;
                  showResults(context);
                },
              ))
          .toList(),
    );
  }
}
