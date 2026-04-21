import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;

  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmError;

  bool isEmailValid(String email) {
<<<<<<< HEAD
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(email);
=======
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
>>>>>>> 6933b38 (Initial Flutter project)
  }

  Future<void> submit() async {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
      confirmError = null;
    });

    bool ok = true;

    if (nameController.text.length < 2) {
      setState(() {
        nameError = "Minimum 2 characters required";
      });
      ok = false;
    }

<<<<<<< HEAD


=======
>>>>>>> 6933b38 (Initial Flutter project)
    if (!isEmailValid(emailController.text)) {
      setState(() {
        emailError = "Invalid email";
      });
      ok = false;
    }

    if (passwordController.text.length < 6) {
      setState(() {
        passwordError = "Minimum 6 characters required";
      });
      ok = false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        confirmError = "Passwords do not match";
      });
      ok = false;
    }

    if (!ok) return;

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );

      if (response.user != null) {
<<<<<<< HEAD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account Created Successfully")),
        );
=======
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Account Created Successfully")));
>>>>>>> 6933b38 (Initial Flutter project)

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed")),
      );
=======
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Registration Failed")));
>>>>>>> 6933b38 (Initial Flutter project)
    }
  }

  void goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.red,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SUCCESS STARTS HERE",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Complete your registration to begin your IELTS journey",
                        textAlign: TextAlign.center,
<<<<<<< HEAD
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
=======
                        style: TextStyle(color: Colors.black87, fontSize: 13),
>>>>>>> 6933b38 (Initial Flutter project)
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Practice daily\nImprove your English\nAchieve your IELTS dream",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "“Small progress every day leads to big results.”",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Color(0xFFFFEBEE),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Container(
                          width: constraints.maxWidth > 500
                              ? 380
                              : constraints.maxWidth * 0.9,
                          padding: EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
<<<<<<< HEAD
                              )
=======
                              ),
>>>>>>> 6933b38 (Initial Flutter project)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "IELTS Preparation System",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Improve your English skills with practice and tests",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 25),
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: "Name",
                                  errorText: nameError,
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              TextField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  errorText: emailError,
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePass,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  errorText: passwordError,
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePass
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscurePass = !obscurePass;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirm,
                                decoration: InputDecoration(
                                  labelText: "Confirm Password",
                                  errorText: confirmError,
                                  prefixIcon: Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirm = !obscureConfirm;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Center(
                                child: Text(
                                  "Already have an account?\nThan please go to login page...",
                                  style: TextStyle(
<<<<<<< HEAD
                                    color: const Color.fromARGB(255, 133, 53, 53),
=======
                                    color: const Color.fromARGB(
                                      255,
                                      133,
                                      53,
                                      53,
                                    ),
>>>>>>> 6933b38 (Initial Flutter project)
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: SizedBox(
                                  width: 180,
                                  child: ElevatedButton(
                                    onPressed: goToLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
<<<<<<< HEAD
                                      padding: EdgeInsets.symmetric(vertical: 12),
=======
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
>>>>>>> 6933b38 (Initial Flutter project)
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      "Login Page",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
