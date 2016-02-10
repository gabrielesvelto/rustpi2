extern crate openssl;

fn main() {
    openssl::ssl::init();
    println!("Hello, world!");
}
