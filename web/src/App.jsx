import { SignIn,SignInButton, SignedIn, SignedOut, UserButton } from '@clerk/clerk-react';
import './App.css'

function App() {

  return (
    <>
      <SignedOut>
        <SignInButton mode="modal" />
      </SignedOut>

      <SignedIn>
        <h1>Welcome!</h1>
        <UserButton />
      </SignedIn>
    </>
  )
}

export default App
