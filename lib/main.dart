import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(NotepadApp());

class NotepadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  @override
  _NotesScreenState createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, String>> notes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    setState(() {
      notes = savedNotes.map((note) {
        final parts = note.split('|');
        return {'title': parts[0], 'content': parts[1]};
      }).toList();
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notes', 
      notes.map((n) => '${n['title']}|${n['content']}').toList());
  }

  void _addOrEditNote({int? index}) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController(
          text: index != null ? notes[index]['title'] : '');
        final contentController = TextEditingController(
          text: index != null ? notes[index]['content'] : '');

        return AlertDialog(
          title: Text(index == null ? 'New Note' : 'Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(hintText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(hintText: 'Content'),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Save'),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    if (index == null) {
                      notes.insert(0, {
                        'title': titleController.text,
                        'content': contentController.text
                      });
                    } else {
                      notes[index] = {
                        'title': titleController.text,
                        'content': contentController.text
                      };
                    }
                  });
                  _saveNotes();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _searchController.text.isEmpty
        ? notes
        : notes.where((note) =>
            note['title']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            note['content']!.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: notes.isEmpty
          ? Center(child: Text('No notes yet!'))
          : ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(filteredNotes[index]['title']!),
                subtitle: Text(filteredNotes[index]['content']!),
                onTap: () => _addOrEditNote(index: index),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteNote(notes.indexOf(filteredNotes[index])),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _addOrEditNote(),
      ),
    );
  }
}