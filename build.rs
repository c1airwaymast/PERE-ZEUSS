use std::env;

fn main() {
    println!("🔥 OPTIMUS ULTIMATE - PME Security Suite 🔥");
    println!("Building advanced security modules...\n");

    // Compile-time optimizations
    println!("cargo:rustc-link-arg=-s");
    println!("cargo:rustc-env=CARGO_CFG_TARGET_FEATURE=+crt-static");
    
    // Platform-specific configurations
    if cfg!(target_os = "windows") {
        println!("cargo:rustc-link-lib=user32");
        println!("cargo:rustc-link-lib=kernel32");
        println!("cargo:rustc-link-lib=advapi32");
        println!("cargo:rustc-link-lib=ntdll");
    }
    
    // Enable all CPU features for maximum performance
    if let Ok(target) = env::var("TARGET") {
        if target.contains("x86_64") {
            println!("cargo:rustc-env=RUSTFLAGS=-C target-cpu=native");
        }
    }
}
