import { db } from './firebase';
import { doc, updateDoc, arrayUnion, arrayRemove, getDoc } from 'firebase/firestore';
import { Project } from './firestoreUser';

export async function addProject(uid: string, project: Omit<Project, 'id'>) {
  const id = Date.now().toString();
  const projectWithId = { ...project, id };
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    projects: arrayUnion(projectWithId)
  });
  return projectWithId;
}

export async function removeProject(uid: string, projectId: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.projects) return;
  const projectToRemove = userData.projects.find((p: any) => p.id === projectId);
  if (projectToRemove) {
    await updateDoc(userRef, {
      projects: arrayRemove(projectToRemove)
    });
  }
}

export async function updateProject(uid: string, updatedProject: Project) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.projects) return;
  const oldProject = userData.projects.find((p: any) => p.id === updatedProject.id);
  if (oldProject) {
    await updateDoc(userRef, {
      projects: arrayRemove(oldProject)
    });
    await updateDoc(userRef, {
      projects: arrayUnion(updatedProject)
    });
  }
}
